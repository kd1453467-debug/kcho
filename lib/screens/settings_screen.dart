import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';

import '../app_scope.dart';
import '../services/notification_service.dart';
import '../services/settings_store.dart';
import '../theme/app_colors.dart';

const String _appVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsStore = SettingsStore();
  final _nameController = TextEditingController();
  final _groqKeyController = TextEditingController();
  Timer? _nameSaveTimer;
  Timer? _groqKeySaveTimer;

  bool _loading = true;
  String _displayName = '';
  bool _reminderEnabled = false;
  int _reminderHour = SettingsStore.defaultReminderHour;
  int _reminderMinute = SettingsStore.defaultReminderMinute;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _settingsStore.getDisplayName();
    final enabled = await _settingsStore.getReminderEnabled();
    final (hour, minute) = await _settingsStore.getReminderTime();
    final groqKey = await _settingsStore.getGroqApiKey();
    if (!mounted) return;
    setState(() {
      _displayName = name;
      _nameController.text = name;
      _reminderEnabled = enabled;
      _reminderHour = hour;
      _reminderMinute = minute;
      _groqKeyController.text = groqKey;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameSaveTimer?.cancel();
    _groqKeySaveTimer?.cancel();
    _nameController.dispose();
    _groqKeyController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() => _displayName = value);
    _nameSaveTimer?.cancel();
    _nameSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _settingsStore.setDisplayName(value.trim());
    });
  }

  void _onGroqKeyChanged(String value) {
    _groqKeySaveTimer?.cancel();
    _groqKeySaveTimer = Timer(const Duration(milliseconds: 500), () {
      _settingsStore.setGroqApiKey(value.trim());
    });
  }

  Future<void> _onReminderToggled(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        await _showAlert('通知が許可されていません', '端末の設定アプリで K帳 の通知を許可してください。');
        return;
      }
      await NotificationService.instance.scheduleDaily(
        hour: _reminderHour,
        minute: _reminderMinute,
      );
    } else {
      await NotificationService.instance.cancel();
    }
    await _settingsStore.setReminderEnabled(value);
    if (!mounted) return;
    setState(() => _reminderEnabled = value);
  }

  Future<void> _onTimeChanged(DateTime dateTime) async {
    setState(() {
      _reminderHour = dateTime.hour;
      _reminderMinute = dateTime.minute;
    });
    await _settingsStore.setReminderTime(dateTime.hour, dateTime.minute);
    if (_reminderEnabled) {
      await NotificationService.instance.scheduleDaily(
        hour: dateTime.hour,
        minute: dateTime.minute,
      );
    }
  }

  Future<void> _showAlert(String title, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final repo = AppScope.of(context);
    final json = const JsonEncoder.withIndent('  ').convert(
      repo.all().map((e) => e.toJson()).toList(),
    );
    final renderBox = context.findRenderObject() as RenderBox?;
    await Share.share(
      json,
      subject: 'K帳 — エクスポート',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final trimmedName = _displayName.trim();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('設定')),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                children: [
                  if (trimmedName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        'こんにちは、$trimmedNameさん',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                  _SettingsSection(
                    header: 'プロフィール',
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: CupertinoTextField(
                          controller: _nameController,
                          onChanged: _onNameChanged,
                          placeholder: '表示名（例: たろう）',
                          decoration: const BoxDecoration(),
                          style: const TextStyle(color: AppColors.inkPrimary, fontSize: 16),
                          placeholderStyle: const TextStyle(color: AppColors.inkSecondary),
                        ),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    header: '学習リマインダー',
                    children: [
                      CupertinoListTile(
                        title: const Text(
                          '毎日リマインダー',
                          style: TextStyle(color: AppColors.inkPrimary),
                        ),
                        trailing: CupertinoSwitch(
                          value: _reminderEnabled,
                          activeTrackColor: AppColors.hankoRed,
                          onChanged: _onReminderToggled,
                        ),
                      ),
                      if (_reminderEnabled)
                        SizedBox(
                          height: 190,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            use24hFormat: true,
                            initialDateTime:
                                DateTime(2000, 1, 1, _reminderHour, _reminderMinute),
                            onDateTimeChanged: _onTimeChanged,
                          ),
                        ),
                    ],
                  ),
                  _SettingsSection(
                    header: 'AI機能',
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: CupertinoTextField(
                          controller: _groqKeyController,
                          onChanged: _onGroqKeyChanged,
                          placeholder: 'Groq API キー',
                          obscureText: true,
                          decoration: const BoxDecoration(),
                          style: const TextStyle(color: AppColors.inkPrimary, fontSize: 16),
                          placeholderStyle: const TextStyle(color: AppColors.inkSecondary),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Text(
                          'console.groq.com で無料で取得できます。入力すると「新規登録」画面でAI自動補完が使えます。',
                          style: TextStyle(color: AppColors.inkSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    header: 'データ',
                    children: [
                      CupertinoListTile(
                        title: const Text(
                          'データをエクスポート',
                          style: TextStyle(color: AppColors.inkPrimary),
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _exportData,
                      ),
                      CupertinoListTile(
                        title: const Text(
                          '登録数',
                          style: TextStyle(color: AppColors.inkPrimary),
                        ),
                        additionalInfo: Text('${repo.totalCount}'),
                      ),
                    ],
                  ),
                  const _SettingsSection(
                    header: 'このアプリについて',
                    children: [
                      CupertinoListTile(
                        title: Text('K帳', style: TextStyle(color: AppColors.inkPrimary)),
                      ),
                      CupertinoListTile(
                        title: Text('バージョン', style: TextStyle(color: AppColors.inkPrimary)),
                        additionalInfo: Text(_appVersion),
                      ),
                      CupertinoListTile(
                        title: Text(
                          'JLPT の単語と文法を学ぶアプリ',
                          style: TextStyle(color: AppColors.inkSecondary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

/// A [CupertinoListSection.insetGrouped] styled as a warm-paper card.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.header, required this.children});

  final String header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: Text(header, style: const TextStyle(color: AppColors.inkSecondary)),
      backgroundColor: AppColors.paperBackground,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.borderLine),
        borderRadius: BorderRadius.circular(10),
      ),
      children: children,
    );
  }
}
