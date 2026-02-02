import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/status_filter_chip.dart';
import 'issue_detail_screen.dart';
import '../issue_report/issue_report_screen.dart';
import '../auth/login_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  List<IssueModel> _allIssues = [];
  List<IssueModel> _filteredIssues = [];
  String _selectedStatus = 'all';
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, int> _issueStats = {};

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if we have a user and no issues loaded yet
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated &&
        !authProvider.isGuest &&
        _allIssues.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadIssues();
      });
    }
  }

  Future<void> _loadIssues() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint(
      '🔄 _loadIssues called - Auth: ${authProvider.isAuthenticated}, Guest: ${authProvider.isGuest}',
    );

    if (!authProvider.isAuthenticated || authProvider.isGuest) {
      debugPrint('❌ User not authenticated or is guest, clearing issues');
      if (mounted) {
        setState(() {
          _allIssues = [];
          _filteredIssues = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userId = authProvider.currentUser!.id;
      final userName = authProvider.currentUser!.name;
      final userEmail = authProvider.currentUser!.email;

      debugPrint(
        '🔍 Loading issues for user: $userName (ID: $userId, Email: $userEmail)',
      );
      debugPrint('🔍 User object: ${authProvider.currentUser.toString()}');

      // Load user's issues
      _allIssues = await _firestoreService.getUserIssues(userId);
      debugPrint('📋 Loaded ${_allIssues.length} issues for user $userName');

      if (_allIssues.isEmpty) {
        debugPrint('❌ NO ISSUES FOUND! Checking possible causes...');
        debugPrint('🔍 User ID being searched: $userId');
        debugPrint('🔍 User authenticated: ${authProvider.isAuthenticated}');
        debugPrint('🔍 User is guest: ${authProvider.isGuest}');

        // Try to get all issues to see if any exist
        debugPrint('🔍 Attempting to get all issues to debug...');
      }

      // Debug: Print issue details
      for (int i = 0; i < _allIssues.length && i < 5; i++) {
        final issue = _allIssues[i];
        debugPrint(
          '📋 Issue $i: ${issue.title} | UserID: ${issue.userId} | Images: ${issue.imageUrls.length} | Status: ${issue.status.toString().split('.').last}',
        );
      }

      // Load user's issue statistics
      _issueStats = await _firestoreService.getUserIssueStats(userId);
      debugPrint('📊 Issue stats: $_issueStats');

      // Apply current filter
      _filterIssues(_selectedStatus);
    } catch (e) {
      debugPrint('❌ Error loading issues: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load issues: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterIssues(String status) {
    if (mounted) {
      setState(() {
        _selectedStatus = status;
        if (status == 'all') {
          _filteredIssues = List.from(_allIssues);
        } else {
          _filteredIssues = _allIssues.where((issue) {
            return issue.status.toString().split('.').last == status;
          }).toList();
        }
      });
    }
  }

  void _navigateToIssueDetail(IssueModel issue) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => IssueDetailScreen(issue: issue)),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  /// Force refresh issues (public method for external calls)
  void forceRefresh() {
    _loadIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show login prompt for unauthenticated users
        if (!authProvider.isAuthenticated) {
          return _buildLoginPrompt();
        }

        // Show guest mode message
        if (authProvider.isGuest) {
          return _buildGuestModeMessage();
        }

        return _buildIssuesScreen(authProvider);
      },
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 80, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  'Sign In Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please sign in to view and track your reported issues.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestModeMessage() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'Guest Mode',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Issue tracking is not available in guest mode. Please create an account to track your reported issues.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssuesScreen(AuthProvider authProvider) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'My Issues',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            debugPrint('🔄 Manual refresh triggered');
                            _loadIssues();
                          },
                          icon: const Icon(Icons.refresh),
                          color: AppColors.primary,
                          tooltip: 'Refresh Issues',
                        ),
                        // Debug button - remove in production
                        IconButton(
                          onPressed: () async {
                            debugPrint('🔧 DEBUG: Force checking all data...');
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            debugPrint(
                              '🔧 Current user: ${authProvider.currentUser?.toString()}',
                            );
                            debugPrint(
                              '🔧 Is authenticated: ${authProvider.isAuthenticated}',
                            );
                            debugPrint('🔧 Is guest: ${authProvider.isGuest}');

                            // Force refresh auth provider
                            await authProvider.forceRefreshUser();

                            // Force reload issues
                            _loadIssues();
                          },
                          icon: const Icon(Icons.bug_report),
                          color: Colors.orange,
                          tooltip: 'Debug Info',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Track the status of your reported issues',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Status Filter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatusFilterChip(
                        label: 'All',
                        isSelected: _selectedStatus == 'all',
                        onTap: () => _filterIssues('all'),
                        count: _issueStats['total'] ?? 0,
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Submitted',
                        isSelected: _selectedStatus == 'submitted',
                        onTap: () => _filterIssues('submitted'),
                        count: _issueStats['submitted'] ?? 0,
                        color: AppColors.submitted,
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Acknowledged',
                        isSelected: _selectedStatus == 'acknowledged',
                        onTap: () => _filterIssues('acknowledged'),
                        count: _issueStats['acknowledged'] ?? 0,
                        color: AppColors.acknowledged,
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'In Progress',
                        isSelected: _selectedStatus == 'inProgress',
                        onTap: () => _filterIssues('inProgress'),
                        count: _issueStats['inProgress'] ?? 0,
                        color: AppColors.inProgress,
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Resolved',
                        isSelected: _selectedStatus == 'resolved',
                        onTap: () => _filterIssues('resolved'),
                        count: _issueStats['resolved'] ?? 0,
                        color: AppColors.resolved,
                      ),
                    ],
                  ),
                ),
              ),

              // Issues List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : _filteredIssues.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadIssues,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredIssues.length,
                          itemBuilder: (context, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 600),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: IssueCard(
                                    issue: _filteredIssues[index],
                                    onTap: () => _navigateToIssueDetail(
                                      _filteredIssues[index],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == 'all' ? 'No Issues Reported' : 'No Issues Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus == 'all'
                ? 'You haven\'t reported any issues yet.\nTap the camera button to report your first issue!'
                : 'No issues found with the selected status.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_selectedStatus == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const IssueReportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Report Issue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
