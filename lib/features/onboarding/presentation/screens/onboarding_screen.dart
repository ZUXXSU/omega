import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../shared/services/storage_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      title: 'Secure by Design',
      subtitle: 'End-to-end encrypted messages using OpenPGP.\nYour keys, your conversations.',
      icon: Icons.lock_outline_rounded,
    ),
    _OnboardingPage(
      title: 'Works with Email',
      subtitle: 'Use any email account.\nNo phone number required.',
      icon: Icons.mail_outline_rounded,
    ),
    _OnboardingPage(
      title: 'No Central Server',
      subtitle: 'Your messages go through your own email provider.\nNo Omega servers store your data.',
      icon: Icons.hub_outlined,
    ),
    _OnboardingPage(
      title: 'Enterprise Ready',
      subtitle: 'MDM support, admin provisioning,\nand team management built in.',
      icon: Icons.business_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await StorageService.setOnboardingComplete();
    if (mounted) context.go(RouteConstants.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmegaColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text('Skip', style: OmegaTextStyles.labelMedium.copyWith(
                  color: OmegaColors.textSecondary,
                )),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _OnboardingPageView(page: _pages[i]),
              ),
            ),
            _BottomSection(
              currentPage: _currentPage,
              pageCount: _pages.length,
              onNext: _next,
              isLast: _currentPage == _pages.length - 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: OmegaColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: OmegaColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: OmegaTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: OmegaTextStyles.bodyLarge.copyWith(
              color: OmegaColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;
  final bool isLast;

  const _BottomSection({
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (i) => _Dot(active: i == currentPage)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: Text(isLast ? 'Get Started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? OmegaColors.primary : OmegaColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
