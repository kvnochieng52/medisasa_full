@extends('adminlte::page')

@section('title', 'User Management')

@section('content_header')
    <div class="row">
        <div class="col-sm-6">
            <h1>User Management</h1>
        </div>
        <div class="col-sm-6">
            <ol class="breadcrumb float-sm-right">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Dashboard</a></li>
                <li class="breadcrumb-item active">Users</li>
            </ol>
        </div>
    </div>
@stop

@section('content')
    <div class="card">
        <div class="card-header">
            <div class="row">
                <div class="col-md-6">
                    <h3 class="card-title">Users List</h3>
                </div>
                <div class="col-md-6 text-right">
                    <a href="{{ route('admin.users.create') }}" class="btn btn-primary">
                        <i class="fas fa-plus"></i> Add New User
                    </a>
                </div>
            </div>
        </div>

        <div class="card-body">
            <!-- Search and Filter Form -->
            <form method="GET" action="{{ route('admin.users.index') }}" class="mb-3">
                <div class="row">
                    <div class="col-md-4">
                        <input type="text" name="search" class="form-control" placeholder="Search users..." value="{{ request('search') }}">
                    </div>
                    <div class="col-md-3">
                        <select name="account_type" class="form-control">
                            <option value="">All Roles</option>
                            <option value="1" {{ request('account_type') == '1' ? 'selected' : '' }}>Standard Users</option>
                            <option value="2" {{ request('account_type') == '2' ? 'selected' : '' }}>Service Providers</option>
                            <option value="3" {{ request('account_type') == '3' ? 'selected' : '' }}>Admins</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <button type="submit" class="btn btn-outline-primary">
                            <i class="fas fa-search"></i> Search
                        </button>
                    </div>
                    <div class="col-md-3 text-right">
                        <a href="{{ route('admin.users.index') }}" class="btn btn-outline-secondary">
                            <i class="fas fa-times"></i> Clear Filters
                        </a>
                    </div>
                </div>
            </form>

            <!-- Users Table -->
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Role</th>
                            <th>Phone</th>
                            <th>Status</th>
                            <th>SP Approved</th>
                            <th>Specializations</th>
                            <th>Created</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($users as $user)
                            <tr>
                                <td>{{ $user->id }}</td>
                                <td>
                                    <strong>{{ $user->name }}</strong>
                                    @if($user->profile_image)
                                        <br><small class="text-muted">Has profile image</small>
                                    @endif
                                </td>
                                <td>{{ $user->email }}</td>
                                <td>
                                    <span class="badge
                                        @if($user->account_type == 1) badge-info
                                        @elseif($user->account_type == 2) badge-warning
                                        @elseif($user->account_type == 3) badge-danger
                                        @else badge-secondary @endif">
                                        {{ $user->role_name }}
                                    </span>
                                </td>
                                <td>{{ $user->telephone ?? 'N/A' }}</td>
                                <td>
                                    @if($user->is_active)
                                        <span class="badge badge-success">Active</span>
                                    @else
                                        <span class="badge badge-secondary">Inactive</span>
                                    @endif
                                </td>
                                <td>
                                    @if($user->account_type == 2)
                                        @if($user->sp_approved == 1)
                                            <span class="badge badge-success">Approved</span>
                                        @elseif($user->sp_approved == 3)
                                            <span class="badge badge-danger">Declined</span>
                                        @else
                                            <span class="badge badge-warning">Pending</span>
                                        @endif
                                    @else
                                        <span class="text-muted">N/A</span>
                                    @endif
                                </td>
                                <td>
                                    @if($user->account_type == 2 && $user->specializations->count() > 0)
                                        <small>
                                            @foreach($user->specializations->take(2) as $spec)
                                                <span class="badge badge-info">{{ $spec->specialization_name }}</span>
                                            @endforeach
                                            @if($user->specializations->count() > 2)
                                                <span class="text-muted">+{{ $user->specializations->count() - 2 }} more</span>
                                            @endif
                                        </small>
                                    @else
                                        <span class="text-muted">None</span>
                                    @endif
                                </td>
                                <td>{{ $user->created_at->format('M d, Y') }}</td>
                                <td>
                                    <div class="btn-group" role="group">
                                        <a href="{{ route('admin.users.show', $user) }}" class="btn btn-sm btn-info" title="View">
                                            <i class="fas fa-eye"></i>
                                        </a>
                                        <a href="{{ route('admin.users.edit', $user) }}" class="btn btn-sm btn-warning" title="Edit">
                                            <i class="fas fa-edit"></i>
                                        </a>

                                        <!-- Toggle Status -->
                                        <form method="POST" action="{{ route('admin.users.toggleStatus', $user) }}" style="display: inline;">
                                            @csrf
                                            @method('PATCH')
                                            <button type="submit" class="btn btn-sm {{ $user->is_active ? 'btn-secondary' : 'btn-success' }}"
                                                    title="{{ $user->is_active ? 'Deactivate' : 'Activate' }}"
                                                    onclick="return confirm('Are you sure you want to {{ $user->is_active ? 'deactivate' : 'activate' }} this user?')">
                                                <i class="fas {{ $user->is_active ? 'fa-ban' : 'fa-check' }}"></i>
                                            </button>
                                        </form>

                                        <!-- Approve Service Provider -->
                                        @if($user->account_type == 2 && !$user->sp_approved)
                                            <form method="POST" action="{{ route('admin.users.approve', $user) }}" style="display: inline;">
                                                @csrf
                                                @method('PATCH')
                                                <button type="submit" class="btn btn-sm btn-success" title="Approve Service Provider"
                                                        onclick="return confirm('Are you sure you want to approve this service provider?')">
                                                    <i class="fas fa-check-circle"></i>
                                                </button>
                                            </form>
                                        @endif

                                        <!-- Delete User -->
                                        @if($user->id !== auth()->id())
                                            <form method="POST" action="{{ route('admin.users.destroy', $user) }}" style="display: inline;">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-sm btn-danger" title="Delete"
                                                        onclick="return confirm('Are you sure you want to delete this user? This action cannot be undone.')">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            </form>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="10" class="text-center">No users found.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="d-flex justify-content-center">
                {{ $users->links() }}
            </div>
        </div>
    </div>
@stop

@section('css')
    <style>
        .table-responsive {
            border-radius: 0.25rem;
        }
        .btn-group .btn {
            margin-right: 2px;
        }
        .badge {
            font-size: 0.75em;
        }
    </style>
@stop

@section('js')
    <script>
        // Auto-hide success messages after 5 seconds
        setTimeout(function() {
            $('.alert-success').fadeOut('slow');
        }, 5000);
    </script>
@stop