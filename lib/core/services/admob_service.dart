// lib/core/services/admob_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_config.dart';

/// Serviço de gerenciamento do AdMob (Rewarded Video).
class AdMobService {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  /// ID do anúncio recompensado de acordo com a plataforma.
  static String get _rewardedAdUnitId {
    if (kIsWeb) {
      return '';
    } else if (Platform.isAndroid) {
      return AppConfig.adMobAndroidRewardedId;
    } else if (Platform.isIOS) {
      return AppConfig.adMobIosRewardedId;
    }
    return '';
  }

  /// Inicializa o Mobile Ads SDK.
  static Future<void> initialize() async {
    // AdMob não suporta Web ou Desktop nativamente no Flutter.
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    await MobileAds.instance.initialize();
    loadRewardedAd(); // pré-carrega o primeiro anúncio
  }

  /// Carrega um anúncio recompensado em background.
  static void loadRewardedAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          // Em produção, implementar retry com backoff
        },
      ),
    );
  }

  /// Retorna true se há um anúncio pronto para exibir (ou no caso da Web/Desktop, sempre true como bypass).
  static bool get isAdReady {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    return _rewardedAd != null;
  }

  /// Exibe o vídeo recompensado.
  /// [onReward] é chamado quando o usuário assiste o vídeo completo.
  static Future<void> showRewardedAd({
    required void Function() onReward,
  }) async {
    // Bypass para Web/Desktop: Se a plataforma não for suportada, libera a recompensa direto.
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      onReward();
      return;
    }

    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // pré-carrega o próximo
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onReward();
      },
    );
  }
}
