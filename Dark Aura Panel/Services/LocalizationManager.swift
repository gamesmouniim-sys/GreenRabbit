import SwiftUI
import Combine

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage = .english {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: saved) {
            language = lang
        }
    }

    func t(_ key: LK) -> String {
        translations[language]?[key] ?? translations[.english]?[key] ?? key.rawValue
    }

    // MARK: - Translation table
    // swiftlint:disable line_length
    private let translations: [AppLanguage: [LK: String]] = [

        // ───────────── ENGLISH ──────────────
        .english: [
            .trainingArmed: "TRAINING ARMED",      .standby: "STANDBY",
            .sensiSetup: "Sensi Setup",             .aimCross: "Aim Cross",
            .trickKey: "Trick Key",                 .deviceOverlay: "Device Info Overlay",
            .phoneSensi: "Mobile Sensi",             .phoneSensiSub: "Auto-tune camera sensitivity",
            .hudMobile: "HUD Mobile",               .hudMobileSub: "Control layout optimizer",
            .phoneDPI: "Mobile DPI",                .phoneDPISub: "In-app render scale preset",
            .gunSensi: "Gun Sensi",                 .gunSensiSub: "Weapon sensitivity profiles",
            .basicAim: "Standard Aim",              .basicAimSub: "Custom crosshair pack",
            .aimSetup: "Expert Aim",                .aimSetupSub: "Size, thickness, gap, opacity",
            .aimColors: "Aim Colors",               .aimColorsSub: "Crosshair color and glow",
            .aimSettings: "Aim Settings",           .aimSettingsSub: "Advanced visualization",
            .ballPaint: "Ball Color",               .ballPaintSub: "Projectile color customization",
            .ballSetup: "Ball Config",              .ballSetupSub: "Trail, speed, hit effects",
            .invisibleBall: "Hide Ball",            .invisibleBallSub: "Minimal projectile visual",
            .fps: "FPS",                            .fpsSub: "Frame rate counter",
            .batteryTemp: "Battery Temp",           .batteryTempSub: "Temperature monitor",
            .ram: "RAM",                            .ramSub: "Memory usage",
            .ping: "Ping",                          .pingSub: "Network latency",
            .deviceDPI: "Device DPI",               .deviceDPISub: "Screen pixel density",
            .enableFeatureFirst: "Enable a feature first",
            .training: "TRAINING",
            .featuresActive: "features active",     .powerOnFromHome: "Power on from Home to enable features",
            .score: "SCORE",                        .time: "TIME",          .exit: "EXIT",
            .activeFeatures: "ACTIVE FEATURES",     .noFeaturesActive: "No features active",
            .deviceInfos: "DEVICE INFOS",           .recommendedSensi: "Recommended Sensi",
            .generateSensi: "Generate",
            .learning: "LEARNING",                  .markComplete: "Mark Complete",
            .completed: "Completed",
            .settings: "SETTINGS",                  .language: "LANGUAGE",
            .shareApp: "Share App",                 .privacyPolicy: "Privacy Policy",
            .rateApp: "Rate App",                   .close: "Close",
            .shareMessage: "Train smarter with Dark Aura Panel — Green Rabbit – the ultimate aim training app!",
            .sensiSetupGroup: "SENSI SETUP",        .aimCrossGroup: "AIM CROSS",
            .trickKeyGroup: "TRICK KEY",            .deviceInfoGroup: "DEVICE INFO",
        ],

        // ───────────── PORTUGUÊS ────────────
        .portuguese: [
            .trainingArmed: "TREINAMENTO ARMADO",  .standby: "EM ESPERA",
            .sensiSetup: "Config. Sensi",           .aimCross: "Mira",
            .trickKey: "Truques",                   .deviceOverlay: "Info do Dispositivo",
            .phoneSensi: "Sensi Móvel",              .phoneSensiSub: "Ajuste automático de sensibilidade",
            .hudMobile: "HUD Mobile",               .hudMobileSub: "Otimizador de layout de controle",
            .phoneDPI: "DPI Móvel",                 .phoneDPISub: "Preset de escala de renderização",
            .gunSensi: "Sensi da Arma",             .gunSensiSub: "Perfis de sensibilidade por arma",
            .basicAim: "Mira Padrão",               .basicAimSub: "Pack de mira personalizada",
            .aimSetup: "Mira Expert",               .aimSetupSub: "Tamanho, espessura, gap, opacidade",
            .aimColors: "Cores da Mira",            .aimColorsSub: "Cor e brilho da mira",
            .aimSettings: "Ajustes de Mira",        .aimSettingsSub: "Visualização avançada",
            .ballPaint: "Cor da Bola",              .ballPaintSub: "Personalização de cor do projétil",
            .ballSetup: "Config. Bola",             .ballSetupSub: "Rastro, velocidade, efeitos",
            .invisibleBall: "Ocultar Bola",         .invisibleBallSub: "Visual mínimo do projétil",
            .fps: "FPS",                            .fpsSub: "Contador de quadros",
            .batteryTemp: "Temp. Bateria",          .batteryTempSub: "Monitor de temperatura",
            .ram: "RAM",                            .ramSub: "Uso de memória",
            .ping: "Ping",                          .pingSub: "Latência de rede",
            .deviceDPI: "DPI do Dispositivo",       .deviceDPISub: "Densidade de pixels da tela",
            .enableFeatureFirst: "Ative um recurso primeiro",
            .training: "TREINAMENTO",
            .featuresActive: "recursos ativos",     .powerOnFromHome: "Ligue em Home para ativar recursos",
            .score: "PONTOS",                       .time: "TEMPO",         .exit: "SAIR",
            .activeFeatures: "RECURSOS ATIVOS",     .noFeaturesActive: "Nenhum recurso ativo",
            .deviceInfos: "INFO DO DISPOSITIVO",    .recommendedSensi: "Sensi Recomendada",
            .generateSensi: "Gerar",
            .learning: "APRENDIZADO",               .markComplete: "Marcar Completo",
            .completed: "Concluído",
            .settings: "CONFIGURAÇÕES",             .language: "IDIOMA",
            .shareApp: "Compartilhar App",          .privacyPolicy: "Política de Privacidade",
            .rateApp: "Avaliar App",                .close: "Fechar",
            .shareMessage: "Treine melhor com Dark Aura Panel — Green Rabbit – o app definitivo de treino de mira!",
            .sensiSetupGroup: "CONFIG. SENSI",      .aimCrossGroup: "MIRA",
            .trickKeyGroup: "TRUQUES",              .deviceInfoGroup: "INFO DISPOSITIVO",
        ],

        // ───────────── ESPAÑOL ──────────────
        .spanish: [
            .trainingArmed: "ENTRENAMIENTO LISTO",  .standby: "EN ESPERA",
            .sensiSetup: "Config. Sensi",            .aimCross: "Mira",
            .trickKey: "Trucos",                     .deviceOverlay: "Info del Dispositivo",
            .phoneSensi: "Sensi Móvil",               .phoneSensiSub: "Ajuste automático de sensibilidad",
            .hudMobile: "HUD Móvil",                 .hudMobileSub: "Optimizador de control",
            .phoneDPI: "DPI Móvil",                  .phoneDPISub: "Preset de escala de renderizado",
            .gunSensi: "Sensi del Arma",             .gunSensiSub: "Perfiles de sensibilidad por arma",
            .basicAim: "Mira Estándar",              .basicAimSub: "Pack de mira personalizado",
            .aimSetup: "Mira Expert",                .aimSetupSub: "Tamaño, grosor, separación, opacidad",
            .aimColors: "Colores de Mira",           .aimColorsSub: "Color y brillo de la mira",
            .aimSettings: "Ajustes de Mira",         .aimSettingsSub: "Visualización avanzada",
            .ballPaint: "Color de Bala",             .ballPaintSub: "Personalización de color del proyectil",
            .ballSetup: "Config. Bala",              .ballSetupSub: "Rastro, velocidad, efectos",
            .invisibleBall: "Ocultar Bala",          .invisibleBallSub: "Visual mínimo del proyectil",
            .fps: "FPS",                             .fpsSub: "Contador de fotogramas",
            .batteryTemp: "Temp. Batería",           .batteryTempSub: "Monitor de temperatura",
            .ram: "RAM",                             .ramSub: "Uso de memoria",
            .ping: "Ping",                           .pingSub: "Latencia de red",
            .deviceDPI: "DPI del Dispositivo",       .deviceDPISub: "Densidad de píxeles de pantalla",
            .enableFeatureFirst: "Activa una función primero",
            .training: "ENTRENAMIENTO",
            .featuresActive: "funciones activas",    .powerOnFromHome: "Enciende en Inicio para activar funciones",
            .score: "PUNTOS",                        .time: "TIEMPO",        .exit: "SALIR",
            .activeFeatures: "FUNCIONES ACTIVAS",    .noFeaturesActive: "Sin funciones activas",
            .deviceInfos: "INFO DISPOSITIVO",        .recommendedSensi: "Sensi Recomendada",
            .generateSensi: "Generar",
            .learning: "APRENDIZAJE",                .markComplete: "Marcar Completo",
            .completed: "Completado",
            .settings: "AJUSTES",                    .language: "IDIOMA",
            .shareApp: "Compartir App",              .privacyPolicy: "Política de Privacidad",
            .rateApp: "Valorar App",                 .close: "Cerrar",
            .shareMessage: "Entrena mejor con Dark Aura Panel — Green Rabbit – ¡la app definitiva de entrenamiento de mira!",
            .sensiSetupGroup: "CONFIG. SENSI",       .aimCrossGroup: "MIRA",
            .trickKeyGroup: "TRUCOS",                .deviceInfoGroup: "INFO DISPOSITIVO",
        ],

        // ───────────── ARABIC ──────────────
        .arabic: [
            .trainingArmed: "التدريب جاهز",        .standby: "في الانتظار",
            .sensiSetup: "إعداد الحساسية",          .aimCross: "الشبكة",
            .trickKey: "الحيل",                     .deviceOverlay: "معلومات الجهاز",
            .phoneSensi: "سنسي موبايل",              .phoneSensiSub: "ضبط تلقائي للحساسية",
            .hudMobile: "واجهة HUD",                .hudMobileSub: "محسّن تخطيط التحكم",
            .phoneDPI: "DPI موبايل",                .phoneDPISub: "إعداد مقياس العرض",
            .gunSensi: "حساسية السلاح",             .gunSensiSub: "ملفات حساسية الأسلحة",
            .basicAim: "تصويب قياسي",               .basicAimSub: "حزمة تصويب مخصصة",
            .aimSetup: "تصويب خبير",                .aimSetupSub: "الحجم، السماكة، الفجوة، الشفافية",
            .aimColors: "ألوان التصويب",             .aimColorsSub: "لون وتوهج الشبكة",
            .aimSettings: "إعدادات التصويب",        .aimSettingsSub: "عرض متقدم",
            .ballPaint: "لون الكرة",                .ballPaintSub: "تخصيص لون المقذوف",
            .ballSetup: "ضبط الكرة",                .ballSetupSub: "أثر، سرعة، تأثيرات الضربة",
            .invisibleBall: "إخفاء الكرة",          .invisibleBallSub: "مظهر مقذوف أدنى",
            .fps: "FPS",                             .fpsSub: "عداد الإطارات",
            .batteryTemp: "حرارة البطارية",          .batteryTempSub: "مراقب درجة الحرارة",
            .ram: "RAM",                             .ramSub: "استخدام الذاكرة",
            .ping: "Ping",                           .pingSub: "تأخر الشبكة",
            .deviceDPI: "دقة الشاشة",               .deviceDPISub: "كثافة بكسل الشاشة",
            .enableFeatureFirst: "فعّل ميزة أولاً",
            .training: "التدريب",
            .featuresActive: "ميزات نشطة",          .powerOnFromHome: "شغّل من الرئيسية لتفعيل الميزات",
            .score: "النقاط",                       .time: "الوقت",         .exit: "خروج",
            .activeFeatures: "الميزات النشطة",       .noFeaturesActive: "لا توجد ميزات نشطة",
            .deviceInfos: "معلومات الجهاز",         .recommendedSensi: "الحساسية الموصى بها",
            .generateSensi: "توليد",
            .learning: "التعلم",                    .markComplete: "وضع علامة مكتمل",
            .completed: "مكتمل",
            .settings: "الإعدادات",                 .language: "اللغة",
            .shareApp: "مشاركة التطبيق",            .privacyPolicy: "سياسة الخصوصية",
            .rateApp: "تقييم التطبيق",              .close: "إغلاق",
            .shareMessage: "تدرّب بذكاء مع Dark Aura Panel — Green Rabbit – تطبيق التدريب على التصويب!",
            .sensiSetupGroup: "إعداد الحساسية",     .aimCrossGroup: "الشبكة",
            .trickKeyGroup: "الحيل",                .deviceInfoGroup: "معلومات الجهاز",
        ],
    ]
    // swiftlint:enable line_length
}
