# Contador de Vida MTG

Aplicação mobile para Magic: The Gathering com foco em partidas multiplayer (2 a 6 jogadores). Interface full‑screen, controles rápidos e experiência otimizada para mesa real.

**Destaques**
1. Mesa dinâmica para 2–6 jogadores com layout automático.
2. Vida em destaque com gestos e botões laterais de ajuste.
3. Contadores secundários em overlay (Veneno, Taxa, Commander Damage).
4. Histórico rápido de eventos.
5. Dado D6/D20 e moeda.
6. Setup com cores WUBRG, reordenação de jogadores e preview da mesa.
7. Persistência total (partida e preferências).

**Requisitos**
1. Flutter 3.x
2. Android SDK (para rodar no Android)

**Rodar no Android**
```bash
flutter pub get
flutter run -d <id_do_dispositivo>
```

Para listar dispositivos:
```bash
flutter devices
```

**Rodar no Web**
```bash
flutter create .
flutter pub get
flutter run -d chrome
```

**Estrutura**
1. `lib/domain` modelos e regras
2. `lib/data` persistência local (Hive)
3. `lib/presentation` UI, telas e providers
4. `lib/core` tema e roteamento

**Ícone e Splash**
1. Ícone: `assets/icon/app_icon.png`
2. Splash: `assets/splash/splash.svg`

Para gerar ícones:
```bash
flutter pub run flutter_launcher_icons:main
```

Para gerar splash:
```bash
flutter pub run flutter_native_splash:create
```

**Licença**
Uso pessoal e experimental.
