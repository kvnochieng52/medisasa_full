<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Specialization;
use App\Models\User;
use App\Models\UserDocument;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AdminUserController extends Controller
{
    private function requireAdmin(Request $request): void
    {
        $user = $request->user();
        if (!$user || (int) $user->account_type !== 3) {
            abort(403, 'Admin access required.');
        }
    }

    // GET /api/admin/users
    public function index(Request $request)
    {
        $this->requireAdmin($request);

        $query = User::with(['specializations', 'documents']);

        if ($request->filled('account_type')) {
            $query->where('account_type', $request->account_type);
        }

        if ($request->filled('sp_approved')) {
            $query->where('sp_approved', $request->sp_approved);
        }

        if ($request->filled('is_active')) {
            $query->where('is_active', $request->is_active);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('telephone', 'like', "%{$search}%");
            });
        }

        $perPage = min((int) $request->input('per_page', 15), 100);
        $users   = $query->orderByDesc('created_at')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data'    => $users->items(),
            'meta'    => [
                'current_page' => $users->currentPage(),
                'last_page'    => $users->lastPage(),
                'per_page'     => $users->perPage(),
                'total'        => $users->total(),
            ],
        ]);
    }

    // GET /api/admin/users/{id}
    public function show(Request $request, $id)
    {
        $this->requireAdmin($request);

        $user = User::with(['specializations', 'documents'])->findOrFail($id);

        return response()->json(['success' => true, 'data' => $user]);
    }

    // GET /api/admin/specializations
    public function specializations(Request $request)
    {
        $this->requireAdmin($request);

        // Select the real columns; the Specialization model exposes a `name`
        // accessor (via $appends) so API consumers see `{id, name}`.
        $specs = Specialization::where('is_active', 1)
            ->orderBy('specialization_name')
            ->get(['id', 'specialization_name']);

        return response()->json(['success' => true, 'data' => $specs]);
    }

    // POST /api/admin/users
    public function store(Request $request)
    {
        $this->requireAdmin($request);

        $validator = Validator::make($request->all(), [
            'name'              => 'required|string|max:255',
            'email'             => 'required|email|max:255|unique:users,email',
            'password'          => 'required|string|min:8',
            'telephone'         => 'nullable|string|max:20',
            'id_number'         => 'nullable|string|max:50',
            'address'           => 'nullable|string|max:500',
            'dob'               => 'nullable|date',
            'account_type'      => 'required|integer|in:1,2,3',
            'licence_number'    => 'nullable|string|max:100',
            'professional_bio'  => 'nullable|string|max:1000',
            'specializations'   => 'nullable|array',
            'specializations.*' => 'exists:specializations,id',
            'is_active'         => 'nullable|boolean',
            'sp_approved'       => 'nullable|integer|in:0,1,3',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $user = User::create([
            'name'             => $request->name,
            'email'            => $request->email,
            'password'         => Hash::make($request->password),
            'telephone'        => $request->telephone,
            'id_number'        => $request->id_number,
            'address'          => $request->address,
            'dob'              => $request->dob,
            'account_type'     => $request->account_type,
            'licence_number'   => $request->licence_number,
            'professional_bio' => $request->professional_bio,
            'is_active'        => $request->boolean('is_active', true) ? 1 : 0,
            'sp_approved'      => $request->account_type == 2 ? ($request->sp_approved ?? 0) : 0,
            'email_verified_at' => now(),
            'first_login'      => 0,
        ]);

        if ($request->account_type == 2 && $request->filled('specializations')) {
            $user->specializations()->attach($request->specializations);
        }

        return response()->json([
            'success' => true,
            'message' => 'User created',
            'data'    => $user->fresh(['specializations']),
        ], 201);
    }

    // PUT /api/admin/users/{id}
    public function update(Request $request, $id)
    {
        $this->requireAdmin($request);

        $user = User::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name'              => 'required|string|max:255',
            'email'             => 'required|email|max:255|unique:users,email,' . $user->id,
            'password'          => 'nullable|string|min:8',
            'telephone'         => 'nullable|string|max:20',
            'id_number'         => 'nullable|string|max:50',
            'address'           => 'nullable|string|max:500',
            'dob'               => 'nullable|date',
            'account_type'      => 'required|integer|in:1,2,3',
            'licence_number'    => 'nullable|string|max:100',
            'professional_bio'  => 'nullable|string|max:1000',
            'specializations'   => 'nullable|array',
            'specializations.*' => 'exists:specializations,id',
            'is_active'         => 'required|boolean',
            'sp_approved'       => 'nullable|integer|in:0,1,3',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $update = [
            'name'             => $request->name,
            'email'            => $request->email,
            'telephone'        => $request->telephone,
            'id_number'        => $request->id_number,
            'address'          => $request->address,
            'dob'              => $request->dob,
            'account_type'     => $request->account_type,
            'licence_number'   => $request->licence_number,
            'professional_bio' => $request->professional_bio,
            'is_active'        => $request->is_active ? 1 : 0,
            'sp_approved'      => $request->account_type == 2 ? ($request->sp_approved ?? $user->sp_approved ?? 0) : 0,
        ];

        if ($request->filled('password')) {
            $update['password'] = Hash::make($request->password);
        }

        $user->update($update);

        if ($request->account_type == 2) {
            $user->specializations()->sync($request->specializations ?? []);
        } else {
            $user->specializations()->detach();
        }

        return response()->json([
            'success' => true,
            'message' => 'User updated',
            'data'    => $user->fresh(['specializations', 'documents']),
        ]);
    }

    // DELETE /api/admin/users/{id}
    public function destroy(Request $request, $id)
    {
        $this->requireAdmin($request);

        $user = User::findOrFail($id);

        if ($user->id === $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'You cannot delete your own account.',
            ], 422);
        }

        $user->delete();

        return response()->json(['success' => true, 'message' => 'User deleted']);
    }

    // PATCH /api/admin/users/{id}/toggle-status
    public function toggleStatus(Request $request, $id)
    {
        $this->requireAdmin($request);

        $user = User::findOrFail($id);
        $user->update(['is_active' => $user->is_active ? 0 : 1]);

        return response()->json([
            'success' => true,
            'message' => $user->is_active ? 'User activated' : 'User deactivated',
            'data'    => $user->fresh(),
        ]);
    }

    // PATCH /api/admin/users/{id}/approve
    public function approveServiceProvider(Request $request, $id)
    {
        $this->requireAdmin($request);

        $user = User::findOrFail($id);
        if ((int) $user->account_type !== 2) {
            return response()->json([
                'success' => false,
                'message' => 'User is not a service provider.',
            ], 422);
        }

        $user->update(['sp_approved' => 1]);

        return response()->json([
            'success' => true,
            'message' => 'Service provider approved',
            'data'    => $user->fresh(),
        ]);
    }

    // PATCH /api/admin/users/{id}/decline
    public function declineServiceProvider(Request $request, $id)
    {
        $this->requireAdmin($request);

        $user = User::findOrFail($id);
        if ((int) $user->account_type !== 2) {
            return response()->json([
                'success' => false,
                'message' => 'User is not a service provider.',
            ], 422);
        }

        $user->update(['sp_approved' => 3]);

        return response()->json([
            'success' => true,
            'message' => 'Service provider declined',
            'data'    => $user->fresh(),
        ]);
    }

    // GET /api/admin/user-documents/{document}/url
    public function documentUrl(Request $request, $documentId)
    {
        $this->requireAdmin($request);

        $document = UserDocument::findOrFail($documentId);
        if (!$document->document_path) {
            return response()->json(['success' => false, 'message' => 'Document path not set.'], 404);
        }

        $candidates = [
            $document->document_path,
            'user_documents/' . basename($document->document_path),
        ];

        foreach ($candidates as $path) {
            if (Storage::disk('public')->exists($path)) {
                return response()->json([
                    'success' => true,
                    'data'    => ['url' => Storage::disk('public')->url($path)],
                ]);
            }
        }

        return response()->json([
            'success' => false,
            'message' => 'Document file not found on disk.',
        ], 404);
    }
}
