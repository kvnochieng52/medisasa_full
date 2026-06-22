<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserDocument;
use App\Models\Specialization;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class UserController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = User::with(['specializations', 'documents']);

        // Filter by role/account type
        if ($request->filled('account_type')) {
            $query->where('account_type', $request->account_type);
        }

        // Search functionality
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('telephone', 'like', "%{$search}%");
            });
        }

        $users = $query->paginate(15);

        return view('admin.users.index', compact('users'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $specializations = Specialization::where('is_active', 1)->get();
        return view('admin.users.create', compact('specializations'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'telephone' => 'nullable|string|max:20',
            'id_number' => 'nullable|string|max:50',
            'address' => 'nullable|string|max:500',
            'dob' => 'nullable|date',
            'account_type' => 'required|integer|in:1,2,3',
            'licence_number' => 'nullable|string|max:100',
            'professional_bio' => 'nullable|string|max:1000',
            'specializations' => 'nullable|array',
            'specializations.*' => 'exists:specializations,id',
        ]);

        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'telephone' => $request->telephone,
            'id_number' => $request->id_number,
            'address' => $request->address,
            'dob' => $request->dob,
            'account_type' => $request->account_type,
            'licence_number' => $request->licence_number,
            'professional_bio' => $request->professional_bio,
            'is_active' => 1,
            'sp_approved' => $request->account_type == 2 ? ($request->sp_approved ?? 0) : 0,
        ]);

        // Assign specializations for service providers
        if ($request->account_type == 2 && $request->filled('specializations')) {
            $user->specializations()->attach($request->specializations);
        }

        return redirect()->route('admin.users.index')
            ->with('success', 'User created successfully.');
    }

    /**
     * Display the specified resource.
     */
    public function show(User $user)
    {
        $user->load(['specializations', 'documents']);
        return view('admin.users.show', compact('user'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(User $user)
    {
        $specializations = Specialization::where('is_active', 1)->get();
        $userSpecializations = $user->specializations->pluck('id')->toArray();

        return view('admin.users.edit', compact('user', 'specializations', 'userSpecializations'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $user)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'nullable|string|min:8|confirmed',
            'telephone' => 'nullable|string|max:20',
            'id_number' => 'nullable|string|max:50',
            'address' => 'nullable|string|max:500',
            'dob' => 'nullable|date',
            'account_type' => 'required|integer|in:1,2,3',
            'licence_number' => 'nullable|string|max:100',
            'professional_bio' => 'nullable|string|max:1000',
            'specializations' => 'nullable|array',
            'specializations.*' => 'exists:specializations,id',
            'is_active' => 'required|boolean',
            'sp_approved' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }

        $updateData = [
            'name' => $request->name,
            'email' => $request->email,
            'telephone' => $request->telephone,
            'id_number' => $request->id_number,
            'address' => $request->address,
            'dob' => $request->dob,
            'account_type' => $request->account_type,
            'licence_number' => $request->licence_number,
            'professional_bio' => $request->professional_bio,
            'is_active' => $request->is_active,
            'sp_approved' => $request->account_type == 2 ? ($request->sp_approved ?? 0) : 0,
        ];

        if ($request->filled('password')) {
            $updateData['password'] = Hash::make($request->password);
        }

        $user->update($updateData);

        // Update specializations for service providers
        if ($request->account_type == 2) {
            $user->specializations()->sync($request->specializations ?? []);
        } else {
            $user->specializations()->detach();
        }

        return redirect()->route('admin.users.index')
            ->with('success', 'User updated successfully.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $user)
    {
        // Don't allow deleting yourself
        if ($user->id === auth()->id()) {
            return redirect()->back()
                ->with('error', 'You cannot delete your own account.');
        }

        $user->delete();

        return redirect()->route('admin.users.index')
            ->with('success', 'User deleted successfully.');
    }

    /**
     * Toggle user active status
     */
    public function toggleStatus(User $user)
    {
        $user->update(['is_active' => !$user->is_active]);

        $status = $user->is_active ? 'activated' : 'deactivated';
        return redirect()->back()
            ->with('success', "User {$status} successfully.");
    }

    /**
     * Approve service provider
     */
    public function approveServiceProvider(User $user)
    {
        if ($user->account_type != 2) {
            return redirect()->back()
                ->with('error', 'User is not a service provider.');
        }

        $user->update(['sp_approved' => 1]);

        return redirect()->back()
            ->with('success', 'Service provider approved successfully.');
    }

    /**
     * Decline service provider
     */
    public function declineServiceProvider(User $user)
    {
        if ($user->account_type != 2) {
            return redirect()->back()
                ->with('error', 'User is not a service provider.');
        }

        $user->update(['sp_approved' => 3]); // 0 = pending, 1 = approved, 3 = declined

        return redirect()->back()
            ->with('success', 'Service provider declined successfully.');
    }

    /**
     * Download user document
     */
    public function downloadDocument(UserDocument $document)
    {
        if (!$document->document_path) {
            return redirect()->back()
                ->with('error', 'Document path not found.');
        }

        // Try different possible paths
        $possiblePaths = [
            public_path('storage/user_documents/' . basename($document->document_path)),
            public_path('storage/' . $document->document_path),
            storage_path('app/public/user_documents/' . basename($document->document_path)),
            storage_path('app/' . $document->document_path),
        ];

        $filePath = null;
        foreach ($possiblePaths as $path) {
            if (file_exists($path)) {
                $filePath = $path;
                break;
            }
        }

        if (!$filePath) {
            return redirect()->back()
                ->with('error', 'Document file not found. Path: ' . $document->document_path);
        }

        return response()->download($filePath);
    }

    /**
     * View user document
     */
    public function viewDocument(UserDocument $document)
    {
        if (!$document->document_path) {
            return redirect()->back()
                ->with('error', 'Document path not found.');
        }

        // Try different possible paths
        $possiblePaths = [
            public_path('storage/user_documents/' . basename($document->document_path)),
            public_path('storage/' . $document->document_path),
            storage_path('app/public/user_documents/' . basename($document->document_path)),
            storage_path('app/' . $document->document_path),
        ];

        $filePath = null;
        foreach ($possiblePaths as $path) {
            if (file_exists($path)) {
                $filePath = $path;
                break;
            }
        }

        if (!$filePath) {
            return redirect()->back()
                ->with('error', 'Document file not found. Path: ' . $document->document_path);
        }

        $mimeType = mime_content_type($filePath);

        return response()->file($filePath, [
            'Content-Type' => $mimeType,
            'Content-Disposition' => 'inline; filename="' . basename($document->document_path) . '"'
        ]);
    }
}
