import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/adaptive_menu.dart';
import 'package:hiddify/features/common/confirmation_dialogs.dart';
import 'package:hiddify/features/common/qr_code_dialog.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_notifier.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 添加一个显示流量超出限额弹窗的函数
Future<void> showTrafficExceededDialog(BuildContext context, WidgetRef ref) async {
  final t = ref.watch(translationsProvider);
  return showDialog(
    context: context,
    barrierDismissible: false, // 用户必须点击按钮关闭对话框
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '流量超出限额提醒',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text('您的账户流量已用尽，无法继续使用服务。请考虑以下选项：'),
              const SizedBox(height: 12),
              const Text('1. 购买新的套餐'),
              const Text('2. 等待下个周期流量重置'),
              const Text('3. 联系客服咨询'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('购买套餐'),
            onPressed: () {
              context.pop();
              const PurchaseRoute().go(context);
            },
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              context.pop();
            },
          ),
        ],
      );
    },
  );
}

// 添加一个显示即将到期提醒的函数
Future<void> showExpirationWarningDialog(BuildContext context, WidgetRef ref, int remainingDays) async {
  final t = ref.watch(translationsProvider);
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('服务即将到期提醒', style: TextStyle(color: Colors.orange)),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Icon(
                Icons.access_time,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text('您的服务将在 $remainingDays 天后到期，为避免服务中断，请及时续费。'),
              const SizedBox(height: 12),
              const Text('1. 可以提前续费以确保服务不中断'),
              const Text('2. 到期后需要重新订阅才能继续使用'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('续费'),
            onPressed: () {
              context.pop();
              const PurchaseRoute().go(context);
            },
          ),
          TextButton(
            child: const Text('稍后提醒'),
            onPressed: () {
              context.pop();
            },
          ),
        ],
      );
    },
  );
}

class ProfileTile extends HookConsumerWidget {
  const ProfileTile({
    super.key,
    required this.profile,
    this.isMain = false,
  });

  final ProfileEntity profile;

  /// home screen active profile card
  final bool isMain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final selectActiveMutation = useMutation(
      initialOnFailure: (err) {
        CustomToast.error(t.presentShortError(err)).show(context);
      },
      initialOnSuccess: () {
        if (context.mounted && context.canPop()) context.pop();
      },
    );

    final subInfo = switch (profile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    // 检查是否流量超出限额和即将到期，如果是活动配置文件且显示在主页面，则显示相应弹窗
    if (isMain && profile.active && subInfo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (subInfo.ratio >= 1) {
          showTrafficExceededDialog(context, ref);
        } else if (!subInfo.isExpired && subInfo.remaining.inDays <= 7) {
          // 获取上次显示提醒的时间
          final prefs = await SharedPreferences.getInstance();
          final lastWarningKey = 'last_expiration_warning_${profile.id}';
          final lastWarningTime = DateTime.tryParse(prefs.getString(lastWarningKey) ?? '');

          final now = DateTime.now();
          if (lastWarningTime == null || now.difference(lastWarningTime).inDays >= 1) {
            // 显示提醒并更新最后提醒时间
            showExpirationWarningDialog(context, ref, subInfo.remaining.inDays);
            prefs.setString(
              lastWarningKey,
              now.toIso8601String(),
            );
          }
        }
      });
    }

    final effectiveMargin = isMain ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.only(left: 12, right: 12, bottom: 12);
    final double effectiveElevation = profile.active ? 12 : 4;
    final effectiveOutlineColor = profile.active ? theme.colorScheme.outlineVariant : Colors.transparent;

    return Card(
      margin: effectiveMargin,
      elevation: effectiveElevation,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: effectiveOutlineColor),
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.transparent,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (profile is RemoteProfileEntity || !isMain) ...[
              SizedBox(
                width: 48,
                child: Semantics(
                  sortKey: const OrdinalSortKey(1),
                  child: ProfileActionButton(profile, !isMain),
                ),
              ),
              VerticalDivider(
                width: 1,
                color: effectiveOutlineColor,
              ),
            ],
            Expanded(
              child: Semantics(
                button: true,
                sortKey: isMain ? const OrdinalSortKey(0) : null,
                focused: isMain,
                liveRegion: isMain,
                namesRoute: isMain,
                label: isMain ? t.profile.activeProfileBtnSemanticLabel : null,
                child: InkWell(
                  onTap: () {
                    if (isMain) {
                      const ProfilesOverviewRoute().go(context);
                    } else {
                      if (selectActiveMutation.state.isInProgress) return;
                      if (profile.active) return;
                      selectActiveMutation.setFuture(
                        ref.read(profilesOverviewNotifierProvider.notifier).selectActiveProfile(profile.id),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMain)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Material(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.transparent,
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      profile.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontFamily: FontFamily.emoji,
                                      ),
                                      semanticsLabel: t.profile.activeProfileNameSemanticLabel(
                                        name: profile.name,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    FluentIcons.caret_down_16_filled,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            profile.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                            semanticsLabel: profile.active
                                ? t.profile.activeProfileNameSemanticLabel(
                                    name: profile.name,
                                  )
                                : t.profile.nonActiveProfileBtnSemanticLabel(
                                    name: profile.name,
                                  ),
                          ),
                        if (subInfo != null) ...[
                          const Gap(4),
                          RemainingTrafficIndicator(subInfo.ratio),
                          const Gap(4),
                          ProfileSubscriptionInfo(subInfo),
                          const Gap(4),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileActionButton extends HookConsumerWidget {
  const ProfileActionButton(this.profile, this.showAllActions, {super.key});

  final ProfileEntity profile;
  final bool showAllActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    if (profile case RemoteProfileEntity() when !showAllActions) {
      return Semantics(
        button: true,
        enabled: !ref.watch(updateProfileProvider(profile.id)).isLoading,
        child: Tooltip(
          message: t.profile.update.tooltip,
          child: InkWell(
            onTap: () {
              if (ref.read(updateProfileProvider(profile.id)).isLoading) {
                return;
              }
              ref.read(updateProfileProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
            },
            child: const Icon(FluentIcons.arrow_sync_24_filled),
          ),
        ),
      );
    }
    return ProfileActionsMenu(
      profile,
      (context, toggleVisibility, _) {
        return Semantics(
          button: true,
          child: Tooltip(
            message: MaterialLocalizations.of(context).showMenuTooltip,
            child: InkWell(
              onTap: toggleVisibility,
              child: Icon(AdaptiveIcon(context).more),
            ),
          ),
        );
      },
    );
  }
}

class ProfileActionsMenu extends HookConsumerWidget {
  const ProfileActionsMenu(this.profile, this.builder, {super.key, this.child});

  final ProfileEntity profile;
  final AdaptiveMenuBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final exportConfigMutation = useMutation(
      initialOnFailure: (err) {
        CustomToast.error(t.presentShortError(err)).show(context);
      },
      initialOnSuccess: () => CustomToast.success(t.profile.share.exportConfigToClipboardSuccess).show(context),
    );
    final deleteProfileMutation = useMutation(
      initialOnFailure: (err) {
        CustomAlertDialog.fromErr(t.presentError(err)).show(context);
      },
    );

    final menuItems = [
      if (profile case RemoteProfileEntity())
        AdaptiveMenuItem(
          title: t.profile.update.buttonTxt,
          icon: FluentIcons.arrow_sync_24_regular,
          onTap: () {
            if (ref.read(updateProfileProvider(profile.id)).isLoading) {
              return;
            }
            ref.read(updateProfileProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
          },
        ),
      AdaptiveMenuItem(
        title: t.profile.share.buttonText,
        icon: AdaptiveIcon(context).share,
        subItems: [
          if (profile case RemoteProfileEntity(:final url, :final name)) ...[
            AdaptiveMenuItem(
              title: t.profile.share.exportSubLinkToClipboard,
              onTap: () async {
                final link = LinkParser.generateSubShareLink(url, name);
                if (link.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    CustomToast(t.profile.share.exportToClipboardSuccess).show(context);
                  }
                }
              },
            ),
            AdaptiveMenuItem(
              title: t.profile.share.subLinkQrCode,
              onTap: () async {
                final link = LinkParser.generateSubShareLink(url, name);
                if (link.isNotEmpty) {
                  await QrCodeDialog(
                    link,
                    message: name,
                  ).show(context);
                }
              },
            ),
          ],
          AdaptiveMenuItem(
            title: t.profile.share.exportConfigToClipboard,
            onTap: () async {
              if (exportConfigMutation.state.isInProgress) {
                return;
              }
              exportConfigMutation.setFuture(
                ref.read(profilesOverviewNotifierProvider.notifier).exportConfigToClipboard(profile),
              );
            },
          ),
        ],
      ),
      AdaptiveMenuItem(
        icon: FluentIcons.edit_24_regular,
        title: t.profile.edit.buttonTxt,
        onTap: () async {
          await ProfileDetailsRoute(profile.id).push(context);
        },
      ),
      AdaptiveMenuItem(
        icon: FluentIcons.delete_24_regular,
        title: t.profile.delete.buttonTxt,
        onTap: () async {
          if (deleteProfileMutation.state.isInProgress) {
            return;
          }
          final deleteConfirmed = await showConfirmationDialog(
            context,
            title: t.profile.delete.buttonTxt,
            message: t.profile.delete.confirmationMsg,
            icon: FluentIcons.delete_24_regular,
          );
          if (deleteConfirmed) {
            deleteProfileMutation.setFuture(
              ref.read(profilesOverviewNotifierProvider.notifier).deleteProfile(profile),
            );
          }
        },
      ),
    ];

    return AdaptiveMenu(
      builder: builder,
      items: menuItems,
      child: child,
    );
  }
}

// TODO add support url
class ProfileSubscriptionInfo extends HookConsumerWidget {
  const ProfileSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.profile.subscription.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.profile.subscription.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.profile.subscription.remainingDuration(duration: "∞"), null);
    } else {
      return (
        t.profile.subscription.remainingDuration(duration: subInfo.remaining.inDays),
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Flexible(
            child: Text(
              subInfo.total > 10 * 1099511627776 //10TB
                  ? "∞ GiB"
                  : subInfo.consumption.sizeOf(subInfo.total),
              semanticsLabel: t.profile.subscription.remainingTrafficSemanticLabel(
                consumed: subInfo.consumption.sizeGB(),
                total: subInfo.total.sizeGB(),
              ),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Flexible(
          child: Text(
            remaining.$1,
            style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// TODO change colors
class RemainingTrafficIndicator extends StatelessWidget {
  const RemainingTrafficIndicator(this.ratio, {super.key});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final startColor = ratio < 0.25
        ? const Color.fromRGBO(93, 205, 251, 1.0)
        : ratio < 0.65
            ? const Color.fromRGBO(205, 199, 64, 1.0)
            : const Color.fromRGBO(241, 82, 81, 1.0);
    final endColor = ratio < 0.25
        ? const Color.fromRGBO(49, 146, 248, 1.0)
        : ratio < 0.65
            ? const Color.fromRGBO(98, 115, 32, 1.0)
            : const Color.fromRGBO(139, 30, 36, 1.0);

    return LinearPercentIndicator(
      percent: ratio,
      animation: true,
      padding: EdgeInsets.zero,
      lineHeight: 6,
      barRadius: const Radius.circular(16),
      linearGradient: LinearGradient(
        colors: [startColor, endColor],
      ),
    );
  }
}
