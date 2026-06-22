<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Admin CRUD for simple lookup / reference tables that the admin maintains:
 *   - specializations
 *   - facility_types
 *   - facility_levels
 *   - insurances
 *   - group_categories
 *   - conditions
 *   - symptoms
 *
 * All endpoints require admin (account_type = 3). The corresponding GET endpoints
 * for public consumption stay where they are (FacilityController, SpecializationController, etc.).
 */
class AdminReferenceController extends Controller
{
    private function ensureAdmin(Request $request): void
    {
        $user = $request->user();
        if (!$user) abort(401, 'Unauthenticated.');

        $isAdmin = (int) $user->account_type === 3;
        $isApprovedSP = (int) $user->account_type === 2 && (int) ($user->sp_approved ?? 0) === 1;

        if (!$isAdmin && !$isApprovedSP) {
            abort(403, 'Admins or approved service providers only.');
        }
    }

    // -----------------------------------------------------------------------
    // Specializations  (name, description, is_active, is_active_for_facility)
    // -----------------------------------------------------------------------

    public function indexSpecializations(Request $r)
    {
        $this->ensureAdmin($r);
        $q = DB::table('specializations')->orderBy('specialization_name');
        if ($search = $r->input('search')) {
            $q->where('specialization_name', 'like', "%{$search}%");
        }
        return response()->json(['success' => true, 'data' => $q->get()]);
    }

    public function storeSpecialization(Request $r)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'specialization_name' => 'required|string|max:255',
            'specialization_description' => 'nullable|string',
            'is_active' => 'nullable|integer|in:0,1',
            'is_active_for_facility' => 'nullable|integer|in:0,1',
        ]);
        $id = DB::table('specializations')->insertGetId(array_merge($d, [
            'is_active' => $d['is_active'] ?? 1,
            'is_active_for_facility' => $d['is_active_for_facility'] ?? 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]));
        return response()->json(['success' => true, 'data' => DB::table('specializations')->find($id)], 201);
    }

    public function updateSpecialization(Request $r, $id)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'specialization_name' => 'sometimes|string|max:255',
            'specialization_description' => 'nullable|string',
            'is_active' => 'nullable|integer|in:0,1',
            'is_active_for_facility' => 'nullable|integer|in:0,1',
        ]);
        DB::table('specializations')->where('id', $id)->update(array_merge($d, ['updated_at' => now()]));
        return response()->json(['success' => true, 'data' => DB::table('specializations')->find($id)]);
    }

    public function destroySpecialization(Request $r, $id)
    {
        $this->ensureAdmin($r);
        DB::table('specializations')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Deleted']);
    }

    // -----------------------------------------------------------------------
    // Facility types  (name, slug, description, is_active, sort_order)
    // -----------------------------------------------------------------------

    public function indexFacilityTypes(Request $r)
    {
        $this->ensureAdmin($r);
        return response()->json(['success' => true, 'data' => DB::table('facility_types')->orderBy('sort_order')->orderBy('name')->get()]);
    }

    public function storeFacilityType(Request $r)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'required|string|max:255|unique:facility_types,name',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);
        $slug = $this->uniqueSlug('facility_types', $d['name']);
        $id = DB::table('facility_types')->insertGetId([
            'name' => $d['name'],
            'slug' => $slug,
            'description' => $d['description'] ?? null,
            'is_active' => $d['is_active'] ?? true,
            'sort_order' => $d['sort_order'] ?? 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['success' => true, 'data' => DB::table('facility_types')->find($id)], 201);
    }

    public function updateFacilityType(Request $r, $id)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'sometimes|string|max:255|unique:facility_types,name,' . $id,
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);
        $update = array_merge($d, ['updated_at' => now()]);
        if (isset($d['name'])) $update['slug'] = $this->uniqueSlug('facility_types', $d['name'], $id);
        DB::table('facility_types')->where('id', $id)->update($update);
        return response()->json(['success' => true, 'data' => DB::table('facility_types')->find($id)]);
    }

    public function destroyFacilityType(Request $r, $id)
    {
        $this->ensureAdmin($r);
        DB::table('facility_types')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Deleted']);
    }

    // -----------------------------------------------------------------------
    // Facility levels  (name, slug, description, level_number, is_active, sort_order)
    // -----------------------------------------------------------------------

    public function indexFacilityLevels(Request $r)
    {
        $this->ensureAdmin($r);
        return response()->json(['success' => true, 'data' => DB::table('facility_levels')->orderBy('level_number')->get()]);
    }

    public function storeFacilityLevel(Request $r)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'required|string|max:255|unique:facility_levels,name',
            'description' => 'nullable|string',
            'level_number' => 'required|integer|min:0',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);
        $id = DB::table('facility_levels')->insertGetId([
            'name' => $d['name'],
            'slug' => $this->uniqueSlug('facility_levels', $d['name']),
            'description' => $d['description'] ?? null,
            'level_number' => $d['level_number'],
            'is_active' => $d['is_active'] ?? true,
            'sort_order' => $d['sort_order'] ?? 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['success' => true, 'data' => DB::table('facility_levels')->find($id)], 201);
    }

    public function updateFacilityLevel(Request $r, $id)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'sometimes|string|max:255|unique:facility_levels,name,' . $id,
            'description' => 'nullable|string',
            'level_number' => 'sometimes|integer|min:0',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);
        $update = array_merge($d, ['updated_at' => now()]);
        if (isset($d['name'])) $update['slug'] = $this->uniqueSlug('facility_levels', $d['name'], $id);
        DB::table('facility_levels')->where('id', $id)->update($update);
        return response()->json(['success' => true, 'data' => DB::table('facility_levels')->find($id)]);
    }

    public function destroyFacilityLevel(Request $r, $id)
    {
        $this->ensureAdmin($r);
        DB::table('facility_levels')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Deleted']);
    }

    // -----------------------------------------------------------------------
    // Insurances  (name, slug, description, is_active, sort_order)
    // -----------------------------------------------------------------------

    public function indexInsurances(Request $r)
    {
        $this->ensureAdmin($r);
        return response()->json(['success' => true, 'data' => DB::table('insurances')->orderBy('sort_order')->orderBy('name')->get()]);
    }

    public function storeInsurance(Request $r)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'required|string|max:255|unique:insurances,name',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);
        $id = DB::table('insurances')->insertGetId([
            'name' => $d['name'],
            'slug' => $this->uniqueSlug('insurances', $d['name']),
            'description' => $d['description'] ?? null,
            'is_active' => $d['is_active'] ?? true,
            'sort_order' => $d['sort_order'] ?? 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['success' => true, 'data' => DB::table('insurances')->find($id)], 201);
    }

    public function updateInsurance(Request $r, $id)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'sometimes|string|max:255|unique:insurances,name,' . $id,
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);
        $update = array_merge($d, ['updated_at' => now()]);
        if (isset($d['name'])) $update['slug'] = $this->uniqueSlug('insurances', $d['name'], $id);
        DB::table('insurances')->where('id', $id)->update($update);
        return response()->json(['success' => true, 'data' => DB::table('insurances')->find($id)]);
    }

    public function destroyInsurance(Request $r, $id)
    {
        $this->ensureAdmin($r);
        DB::table('insurances')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Deleted']);
    }

    // -----------------------------------------------------------------------
    // Group categories  (name, slug, description, position)
    // -----------------------------------------------------------------------

    public function indexGroupCategories(Request $r)
    {
        $this->ensureAdmin($r);
        return response()->json(['success' => true, 'data' => DB::table('group_categories')->orderBy('position')->orderBy('name')->get()]);
    }

    public function storeGroupCategory(Request $r)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'position' => 'nullable|integer|min:0',
        ]);
        $id = DB::table('group_categories')->insertGetId([
            'name' => $d['name'],
            'slug' => $this->uniqueSlug('group_categories', $d['name']),
            'description' => $d['description'] ?? null,
            'position' => $d['position'] ?? 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['success' => true, 'data' => DB::table('group_categories')->find($id)], 201);
    }

    public function updateGroupCategory(Request $r, $id)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'position' => 'nullable|integer|min:0',
        ]);
        $update = array_merge($d, ['updated_at' => now()]);
        if (isset($d['name'])) $update['slug'] = $this->uniqueSlug('group_categories', $d['name'], $id);
        DB::table('group_categories')->where('id', $id)->update($update);
        return response()->json(['success' => true, 'data' => DB::table('group_categories')->find($id)]);
    }

    public function destroyGroupCategory(Request $r, $id)
    {
        $this->ensureAdmin($r);
        DB::table('group_categories')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Deleted']);
    }

    // -----------------------------------------------------------------------
    // Conditions  (name, description, is_active)
    // -----------------------------------------------------------------------

    public function indexConditions(Request $r)
    {
        $this->ensureAdmin($r);
        return response()->json(['success' => true, 'data' => DB::table('conditions')->orderBy('name')->get()]);
    }

    public function storeCondition(Request $r)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
        ]);
        $id = DB::table('conditions')->insertGetId([
            'name' => $d['name'],
            'description' => $d['description'] ?? null,
            'is_active' => $d['is_active'] ?? true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['success' => true, 'data' => DB::table('conditions')->find($id)], 201);
    }

    public function updateCondition(Request $r, $id)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
        ]);
        DB::table('conditions')->where('id', $id)->update(array_merge($d, ['updated_at' => now()]));
        return response()->json(['success' => true, 'data' => DB::table('conditions')->find($id)]);
    }

    public function destroyCondition(Request $r, $id)
    {
        $this->ensureAdmin($r);
        DB::table('conditions')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Deleted']);
    }

    // -----------------------------------------------------------------------
    // Symptoms  (name, description, is_active)
    // -----------------------------------------------------------------------

    public function indexSymptoms(Request $r)
    {
        $this->ensureAdmin($r);
        return response()->json(['success' => true, 'data' => DB::table('symptoms')->orderBy('name')->get()]);
    }

    public function storeSymptom(Request $r)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
        ]);
        $id = DB::table('symptoms')->insertGetId([
            'name' => $d['name'],
            'description' => $d['description'] ?? null,
            'is_active' => $d['is_active'] ?? true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['success' => true, 'data' => DB::table('symptoms')->find($id)], 201);
    }

    public function updateSymptom(Request $r, $id)
    {
        $this->ensureAdmin($r);
        $d = $r->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'nullable|boolean',
        ]);
        DB::table('symptoms')->where('id', $id)->update(array_merge($d, ['updated_at' => now()]));
        return response()->json(['success' => true, 'data' => DB::table('symptoms')->find($id)]);
    }

    public function destroySymptom(Request $r, $id)
    {
        $this->ensureAdmin($r);
        DB::table('symptoms')->where('id', $id)->delete();
        return response()->json(['success' => true, 'message' => 'Deleted']);
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private function uniqueSlug(string $table, string $base, ?int $exceptId = null): string
    {
        $slug = Str::slug($base);
        $i = 0;
        while (true) {
            $candidate = $i === 0 ? $slug : "{$slug}-{$i}";
            $q = DB::table($table)->where('slug', $candidate);
            if ($exceptId) $q->where('id', '!=', $exceptId);
            if (!$q->exists()) return $candidate;
            $i++;
        }
    }
}
