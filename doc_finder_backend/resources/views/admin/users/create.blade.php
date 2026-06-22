@extends('adminlte::page')

@section('title', 'Create User')

@section('content_header')
    <div class="row">
        <div class="col-sm-6">
            <h1>Create New User</h1>
        </div>
        <div class="col-sm-6">
            <ol class="breadcrumb float-sm-right">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Dashboard</a></li>
                <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Users</a></li>
                <li class="breadcrumb-item active">Create</li>
            </ol>
        </div>
    </div>
@stop

@section('content')
    <div class="card">
        <div class="card-header">
            <h3 class="card-title">User Information</h3>
        </div>

        <form method="POST" action="{{ route('admin.users.store') }}">
            @csrf
            <div class="card-body">
                <div class="row">
                    <!-- Basic Information -->
                    <div class="col-md-6">
                        <h5 class="mb-3">Basic Information</h5>

                        <div class="form-group">
                            <label for="name">Full Name <span class="text-danger">*</span></label>
                            <input type="text" class="form-control @error('name') is-invalid @enderror"
                                   id="name" name="name" value="{{ old('name') }}" required>
                            @error('name')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>

                        <div class="form-group">
                            <label for="email">Email Address <span class="text-danger">*</span></label>
                            <input type="email" class="form-control @error('email') is-invalid @enderror"
                                   id="email" name="email" value="{{ old('email') }}" required>
                            @error('email')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>

                        <div class="form-group">
                            <label for="password">Password <span class="text-danger">*</span></label>
                            <input type="password" class="form-control @error('password') is-invalid @enderror"
                                   id="password" name="password" required>
                            @error('password')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>

                        <div class="form-group">
                            <label for="password_confirmation">Confirm Password <span class="text-danger">*</span></label>
                            <input type="password" class="form-control"
                                   id="password_confirmation" name="password_confirmation" required>
                        </div>

                        <div class="form-group">
                            <label for="account_type">User Role <span class="text-danger">*</span></label>
                            <select class="form-control @error('account_type') is-invalid @enderror"
                                    id="account_type" name="account_type" required>
                                <option value="">Select Role</option>
                                <option value="1" {{ old('account_type') == '1' ? 'selected' : '' }}>Standard User</option>
                                <option value="2" {{ old('account_type') == '2' ? 'selected' : '' }}>Service Provider</option>
                                <option value="3" {{ old('account_type') == '3' ? 'selected' : '' }}>Admin</option>
                            </select>
                            @error('account_type')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>
                    </div>

                    <!-- Contact Information -->
                    <div class="col-md-6">
                        <h5 class="mb-3">Contact Information</h5>

                        <div class="form-group">
                            <label for="telephone">Phone Number</label>
                            <input type="text" class="form-control @error('telephone') is-invalid @enderror"
                                   id="telephone" name="telephone" value="{{ old('telephone') }}">
                            @error('telephone')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>

                        <div class="form-group">
                            <label for="id_number">ID Number</label>
                            <input type="text" class="form-control @error('id_number') is-invalid @enderror"
                                   id="id_number" name="id_number" value="{{ old('id_number') }}">
                            @error('id_number')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>

                        <div class="form-group">
                            <label for="address">Address</label>
                            <textarea class="form-control @error('address') is-invalid @enderror"
                                      id="address" name="address" rows="3">{{ old('address') }}</textarea>
                            @error('address')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>

                        <div class="form-group">
                            <label for="dob">Date of Birth</label>
                            <input type="date" class="form-control @error('dob') is-invalid @enderror"
                                   id="dob" name="dob" value="{{ old('dob') }}">
                            @error('dob')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>
                    </div>
                </div>

                <!-- Service Provider Specific Fields -->
                <div id="service-provider-fields" style="display: none;">
                    <hr>
                    <h5 class="mb-3">Service Provider Information</h5>
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label for="licence_number">License Number</label>
                                <input type="text" class="form-control @error('licence_number') is-invalid @enderror"
                                       id="licence_number" name="licence_number" value="{{ old('licence_number') }}">
                                @error('licence_number')
                                    <span class="invalid-feedback">{{ $message }}</span>
                                @enderror
                            </div>

                            <div class="form-group">
                                <div class="custom-control custom-checkbox">
                                    <input type="checkbox" class="custom-control-input" id="sp_approved" name="sp_approved" value="1" {{ old('sp_approved') ? 'checked' : '' }}>
                                    <label class="custom-control-label" for="sp_approved">
                                        Approve Service Provider
                                    </label>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label for="professional_bio">Professional Bio</label>
                                <textarea class="form-control @error('professional_bio') is-invalid @enderror"
                                          id="professional_bio" name="professional_bio" rows="4">{{ old('professional_bio') }}</textarea>
                                @error('professional_bio')
                                    <span class="invalid-feedback">{{ $message }}</span>
                                @enderror
                            </div>
                        </div>
                    </div>

                    <!-- Specializations -->
                    <div class="form-group">
                        <label>Specializations</label>
                        <div class="row">
                            @foreach($specializations as $specialization)
                                <div class="col-md-4 mb-2">
                                    <div class="custom-control custom-checkbox">
                                        <input type="checkbox" class="custom-control-input"
                                               id="spec_{{ $specialization->id }}"
                                               name="specializations[]"
                                               value="{{ $specialization->id }}"
                                               {{ in_array($specialization->id, old('specializations', [])) ? 'checked' : '' }}>
                                        <label class="custom-control-label" for="spec_{{ $specialization->id }}">
                                            {{ $specialization->specialization_name }}
                                        </label>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                        @error('specializations')
                            <span class="text-danger">{{ $message }}</span>
                        @enderror
                    </div>
                </div>
            </div>

            <div class="card-footer">
                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-save"></i> Create User
                </button>
                <a href="{{ route('admin.users.index') }}" class="btn btn-secondary">
                    <i class="fas fa-times"></i> Cancel
                </a>
            </div>
        </form>
    </div>
@stop

@section('js')
    <script>
        $(document).ready(function() {
            // Show/hide service provider fields based on account type
            $('#account_type').change(function() {
                if ($(this).val() == '2') {
                    $('#service-provider-fields').show();
                } else {
                    $('#service-provider-fields').hide();
                }
            });

            // Trigger change event on page load
            $('#account_type').trigger('change');
        });
    </script>
@stop