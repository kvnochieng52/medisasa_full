@extends('adminlte::page')

@section('title', 'User Details')

@section('content_header')
    <div class="row">
        <div class="col-sm-6">
            <h1>User Details</h1>
        </div>
        <div class="col-sm-6">
            <ol class="breadcrumb float-sm-right">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Dashboard</a></li>
                <li class="breadcrumb-item"><a href="{{ route('admin.users.index') }}">Users</a></li>
                <li class="breadcrumb-item active">{{ $user->name }}</li>
            </ol>
        </div>
    </div>
@stop

@section('content')
    <div class="row">
        <!-- User Basic Info -->
        <div class="col-md-8">
            <!-- Profile Photo and Basic Info -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">User Information</h3>
                    <div class="card-tools">
                        <a href="{{ route('admin.users.edit', $user) }}" class="btn btn-sm btn-warning">
                            <i class="fas fa-edit"></i> Edit User
                        </a>
                    </div>
                </div>
                <div class="card-body">
                    <!-- Profile Photo Section -->
                    <div class="row mb-4">
                        <div class="col-md-3 text-center">
                            @if($user->profile_image)
                                <img src="{{ asset('storage/' . $user->profile_image) }}"
                                     alt="{{ $user->name }}"
                                     class="img-fluid rounded-circle mb-2"
                                     style="width: 150px; height: 150px; object-fit: cover; border: 3px solid #007bff;">
                            @else
                                <div class="bg-secondary rounded-circle d-inline-flex align-items-center justify-content-center mb-2"
                                     style="width: 150px; height: 150px; border: 3px solid #6c757d;">
                                    <i class="fas fa-user fa-4x text-white"></i>
                                </div>
                            @endif
                            <h5 class="mt-2">{{ $user->name }}</h5>
                            <p class="text-muted">{{ $user->email }}</p>
                        </div>
                        <div class="col-md-9">
                            <!-- Status Badges -->
                            <div class="mb-3">
                                <span class="badge badge-lg
                                    @if($user->account_type == 1) badge-info
                                    @elseif($user->account_type == 2) badge-warning
                                    @elseif($user->account_type == 3) badge-danger
                                    @else badge-secondary @endif">
                                    <i class="fas fa-user-tag"></i> {{ $user->role_name }}
                                </span>

                                @if($user->is_active)
                                    <span class="badge badge-lg badge-success">
                                        <i class="fas fa-check-circle"></i> Active
                                    </span>
                                @else
                                    <span class="badge badge-lg badge-secondary">
                                        <i class="fas fa-ban"></i> Inactive
                                    </span>
                                @endif

                                @if($user->account_type == 2)
                                    @if($user->sp_approved == 1)
                                        <span class="badge badge-lg badge-success">
                                            <i class="fas fa-check-circle"></i> Approved Service Provider
                                        </span>
                                    @elseif($user->sp_approved == 3)
                                        <span class="badge badge-lg badge-danger">
                                            <i class="fas fa-times-circle"></i> Declined Service Provider
                                        </span>
                                    @else
                                        <span class="badge badge-lg badge-warning">
                                            <i class="fas fa-clock"></i> Pending Approval
                                        </span>
                                    @endif
                                @endif
                            </div>

                            <!-- Quick Stats -->
                            <div class="row">
                                <div class="col-md-4">
                                    <div class="info-box bg-light">
                                        <span class="info-box-icon bg-info">
                                            <i class="fas fa-calendar-alt"></i>
                                        </span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Member Since</span>
                                            <span class="info-box-number">{{ $user->created_at->format('M Y') }}</span>
                                        </div>
                                    </div>
                                </div>
                                @if($user->account_type == 2)
                                    <div class="col-md-4">
                                        <div class="info-box bg-light">
                                            <span class="info-box-icon bg-warning">
                                                <i class="fas fa-stethoscope"></i>
                                            </span>
                                            <div class="info-box-content">
                                                <span class="info-box-text">Specializations</span>
                                                <span class="info-box-number">{{ $user->specializations->count() }}</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="info-box bg-light">
                                            <span class="info-box-icon bg-success">
                                                <i class="fas fa-file-medical"></i>
                                            </span>
                                            <div class="info-box-content">
                                                <span class="info-box-text">Documents</span>
                                                <span class="info-box-number">{{ $user->documents->count() }}</span>
                                            </div>
                                        </div>
                                    </div>
                                @endif
                            </div>
                        </div>
                    </div>

                    <hr>

                    <!-- Detailed Information -->
                    <div class="row">
                        <div class="col-md-6">
                            <h6><i class="fas fa-info-circle"></i> Basic Information</h6>
                            <table class="table table-sm table-borderless">
                                <tr>
                                    <th width="40%">Full Name:</th>
                                    <td>{{ $user->name }}</td>
                                </tr>
                                <tr>
                                    <th>Email:</th>
                                    <td>{{ $user->email }}</td>
                                </tr>
                                <tr>
                                    <th>Phone:</th>
                                    <td>{{ $user->telephone ?? 'Not provided' }}</td>
                                </tr>
                                <tr>
                                    <th>ID Number:</th>
                                    <td>{{ $user->id_number ?? 'Not provided' }}</td>
                                </tr>
                                <tr>
                                    <th>Date of Birth:</th>
                                    <td>{{ $user->dob ? \Carbon\Carbon::parse($user->dob)->format('M d, Y') : 'Not provided' }}</td>
                                </tr>
                                <tr>
                                    <th>Address:</th>
                                    <td>{{ $user->address ?? 'Not provided' }}</td>
                                </tr>
                            </table>
                        </div>
                        <div class="col-md-6">
                            <h6><i class="fas fa-cog"></i> Account Information</h6>
                            <table class="table table-sm table-borderless">
                                <tr>
                                    <th width="40%">Account Type:</th>
                                    <td>
                                        <span class="badge
                                            @if($user->account_type == 1) badge-info
                                            @elseif($user->account_type == 2) badge-warning
                                            @elseif($user->account_type == 3) badge-danger
                                            @else badge-secondary @endif">
                                            {{ $user->role_name }}
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <th>Status:</th>
                                    <td>
                                        @if($user->is_active)
                                            <span class="badge badge-success">Active</span>
                                        @else
                                            <span class="badge badge-secondary">Inactive</span>
                                        @endif
                                    </td>
                                </tr>
                                <tr>
                                    <th>Created:</th>
                                    <td>{{ $user->created_at->format('M d, Y H:i') }}</td>
                                </tr>
                                <tr>
                                    <th>Last Updated:</th>
                                    <td>{{ $user->updated_at->format('M d, Y H:i') }}</td>
                                </tr>
                                @if($user->account_type == 2)
                                    <tr>
                                        <th>SP Status:</th>
                                        <td>
                                            @if($user->sp_approved == 1)
                                                <span class="badge badge-success">Approved</span>
                                            @elseif($user->sp_approved == 3)
                                                <span class="badge badge-danger">Declined</span>
                                            @else
                                                <span class="badge badge-warning">Pending</span>
                                            @endif
                                        </td>
                                    </tr>
                                @endif
                            </table>
                        </div>
                    </div>

                    @if($user->account_type == 2)
                        <hr>
                        <h6><i class="fas fa-user-md"></i> Service Provider Information</h6>
                        <div class="row">
                            <div class="col-md-6">
                                <table class="table table-sm table-borderless">
                                    <tr>
                                        <th width="40%">License Number:</th>
                                        <td>{{ $user->licence_number ?? 'Not provided' }}</td>
                                    </tr>
                                </table>
                            </div>
                            <div class="col-md-6">
                                <strong>Professional Bio:</strong>
                                <p class="mt-2">{{ $user->professional_bio ?? 'No bio provided' }}</p>
                            </div>
                        </div>
                    @endif
                </div>
            </div>

            @if($user->account_type == 2 && $user->specializations->count() > 0)
                <!-- Specializations -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="fas fa-stethoscope"></i> Specializations</h3>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            @foreach($user->specializations as $specialization)
                                <div class="col-md-4 mb-2">
                                    <span class="badge badge-info badge-lg">
                                        <i class="fas fa-medical-note"></i> {{ $specialization->specialization_name }}
                                    </span>
                                </div>
                            @endforeach
                        </div>
                    </div>
                </div>
            @endif

            @if($user->account_type == 2 && $user->documents->count() > 0)
                <!-- Documents -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="fas fa-file-medical"></i> Documents</h3>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-sm table-hover">
                                <thead class="thead-light">
                                    <tr>
                                        <th>Document Type</th>
                                        <th>File Name</th>
                                        <th>Status</th>
                                        <th>Uploaded</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($user->documents as $document)
                                        <tr>
                                            <td>
                                                <strong>{{ $document->document_type }}</strong>
                                            </td>
                                            <td>
                                                @if($document->document_path)
                                                    <code>{{ basename($document->document_path) }}</code>
                                                @else
                                                    <span class="text-muted">No file</span>
                                                @endif
                                            </td>
                                            <td>
                                                @if($document->is_active)
                                                    <span class="badge badge-success">Active</span>
                                                @else
                                                    <span class="badge badge-secondary">Inactive</span>
                                                @endif
                                            </td>
                                            <td>{{ $document->created_at->format('M d, Y') }}</td>
                                            <td>
                                                @php
                                                    $fileExists = false;
                                                    if($document->document_path) {
                                                        $possiblePaths = [
                                                            public_path('storage/user_documents/' . basename($document->document_path)),
                                                            public_path('storage/' . $document->document_path),
                                                            storage_path('app/public/user_documents/' . basename($document->document_path)),
                                                            storage_path('app/' . $document->document_path),
                                                        ];

                                                        foreach ($possiblePaths as $path) {
                                                            if (file_exists($path)) {
                                                                $fileExists = true;
                                                                break;
                                                            }
                                                        }
                                                    }
                                                @endphp
                                                @if($document->document_path && $fileExists)
                                                    <div class="btn-group btn-group-sm" role="group">
                                                        <a href="{{ route('admin.users.documents.view', $document) }}"
                                                           class="btn btn-info btn-sm"
                                                           title="View Document"
                                                           target="_blank">
                                                            <i class="fas fa-eye"></i> View
                                                        </a>
                                                        <a href="{{ route('admin.users.documents.download', $document) }}"
                                                           class="btn btn-success btn-sm"
                                                           title="Download Document">
                                                            <i class="fas fa-download"></i> Download
                                                        </a>
                                                    </div>
                                                @else
                                                    <span class="text-muted">File not available</span>
                                                    @if($document->document_path)
                                                        <br><small class="text-danger">Path: {{ $document->document_path }}</small>
                                                    @endif
                                                @endif
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            @endif
        </div>

        <!-- Action Panel -->
        <div class="col-md-4">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title"><i class="fas fa-tools"></i> Actions</h3>
                </div>
                <div class="card-body">
                    <div class="d-grid gap-2">
                        <!-- Edit User -->
                        <a href="{{ route('admin.users.edit', $user) }}" class="btn btn-warning btn-block mb-2">
                            <i class="fas fa-edit"></i> Edit User Information
                        </a>

                        <!-- Toggle Status -->
                        <form method="POST" action="{{ route('admin.users.toggleStatus', $user) }}" class="mb-2">
                            @csrf
                            @method('PATCH')
                            <button type="submit" class="btn btn-block {{ $user->is_active ? 'btn-secondary' : 'btn-success' }}"
                                    onclick="return confirm('Are you sure you want to {{ $user->is_active ? 'deactivate' : 'activate' }} this user?')">
                                @if($user->is_active)
                                    <i class="fas fa-ban"></i> Deactivate User
                                @else
                                    <i class="fas fa-check"></i> Activate User
                                @endif
                            </button>
                        </form>

                        @if($user->account_type == 2)
                            <!-- Service Provider Actions -->
                            <div class="card border-warning">
                                <div class="card-header bg-warning text-white">
                                    <h6 class="card-title mb-0"><i class="fas fa-user-md"></i> Service Provider Actions</h6>
                                </div>
                                <div class="card-body p-2">
                                    @if($user->sp_approved == 0)
                                        <!-- Pending - Show Approve/Decline -->
                                        <form method="POST" action="{{ route('admin.users.approve', $user) }}" class="mb-2">
                                            @csrf
                                            @method('PATCH')
                                            <button type="submit" class="btn btn-success btn-sm btn-block"
                                                    onclick="return confirm('Are you sure you want to approve this service provider?')">
                                                <i class="fas fa-check-circle"></i> Approve Service Provider
                                            </button>
                                        </form>
                                        <form method="POST" action="{{ route('admin.users.decline', $user) }}">
                                            @csrf
                                            @method('PATCH')
                                            <button type="submit" class="btn btn-danger btn-sm btn-block"
                                                    onclick="return confirm('Are you sure you want to decline this service provider?')">
                                                <i class="fas fa-times-circle"></i> Decline Service Provider
                                            </button>
                                        </form>
                                    @elseif($user->sp_approved == 1)
                                        <!-- Approved - Show Decline Option -->
                                        <div class="alert alert-success alert-sm mb-2">
                                            <i class="fas fa-check-circle"></i> Currently Approved
                                        </div>
                                        <form method="POST" action="{{ route('admin.users.decline', $user) }}">
                                            @csrf
                                            @method('PATCH')
                                            <button type="submit" class="btn btn-warning btn-sm btn-block"
                                                    onclick="return confirm('Are you sure you want to decline this approved service provider?')">
                                                <i class="fas fa-times-circle"></i> Revoke Approval
                                            </button>
                                        </form>
                                    @elseif($user->sp_approved == 3)
                                        <!-- Declined - Show Approve Option -->
                                        <div class="alert alert-danger alert-sm mb-2">
                                            <i class="fas fa-times-circle"></i> Currently Declined
                                        </div>
                                        <form method="POST" action="{{ route('admin.users.approve', $user) }}">
                                            @csrf
                                            @method('PATCH')
                                            <button type="submit" class="btn btn-success btn-sm btn-block"
                                                    onclick="return confirm('Are you sure you want to approve this declined service provider?')">
                                                <i class="fas fa-check-circle"></i> Approve Service Provider
                                            </button>
                                        </form>
                                    @endif
                                </div>
                            </div>
                        @endif

                        @if($user->id !== auth()->id())
                            <!-- Delete User -->
                            <form method="POST" action="{{ route('admin.users.destroy', $user) }}" class="mt-3">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-danger btn-block"
                                        onclick="return confirm('Are you sure you want to delete this user? This action cannot be undone.')">
                                    <i class="fas fa-trash"></i> Delete User
                                </button>
                            </form>
                        @endif

                        <!-- Navigation -->
                        <a href="{{ route('admin.users.index') }}" class="btn btn-info btn-block mt-3">
                            <i class="fas fa-arrow-left"></i> Back to Users List
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
@stop

@section('css')
    <style>
        .badge-lg {
            font-size: 0.9em;
            padding: 0.5rem 0.75rem;
        }
        .info-box {
            border-radius: 0.5rem;
        }
        .info-box-icon {
            border-radius: 0.5rem 0 0 0.5rem;
        }
        .alert-sm {
            padding: 0.5rem;
            margin-bottom: 0.5rem;
            font-size: 0.875rem;
        }
        .table th {
            border-top: none;
            font-weight: 600;
        }
        .card-header h6 {
            margin: 0;
        }
        .btn-group-sm .btn {
            font-size: 0.8rem;
        }
    </style>
@stop

@section('js')
    <script>
        // Auto-hide success messages after 5 seconds
        setTimeout(function() {
            $('.alert-success').not('.alert-sm').fadeOut('slow');
        }, 5000);
    </script>
@stop