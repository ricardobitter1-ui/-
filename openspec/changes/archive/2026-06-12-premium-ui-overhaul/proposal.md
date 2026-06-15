# Proposal: Premium UI Overhaul

## Why

Atualmente, o aplicativo possui uma interface funcional baseada no Material Design 3 padrão, mas carece de uma identidade visual distinta e "premium". Para atrair e reter usuários em um mercado competitivo de To-Do lists, precisamos elevar a estética para um nível de alta fidelidade (Hi-Fi), utilizando micro-interações, tipografia moderna e uma paleta de cores sofisticada definida no nosso [Style Guide](file:///c:/Users/Ricardo%20Bitter/Documents/Exm%20to%20do/openspec/style_guide.md).

Esta mudança prepara o terreno para o roadmap futuro (colaboração e estatísticas) garantindo que a base de UI seja sólida e escalável.

## Goals

- **Visual Excellence**: Implementar o "Mixed Mode" (Light background com Dark Focus cards) com sombras suaves e bordas de 24px.
- **Top-tier Typography**: Integrar `google_fonts` (Inter/Outfit) para uma leitura mais fluída e moderna.
- **Dynamic Feedback**: Adicionar uma barra de progresso diário animada e um seletor de data horizontal intuitivo.
- **Personalization**: Implementar o sistema de avatares com fallback para a primeira letra do nome do usuário.
- **Zero Regression**: Garantir que as funcionalidades de backend (Firebase, Auth, Notificações) permaneçam intactas após a reestruturação visual.

## Impact

- **`lib/ui/theme/app_theme.dart`**: Redefinição total de cores, fontes e estilos de componentes.
- **`lib/ui/screens/home_screen.dart`**: Reconstrução do layout para suportar as novas seções (Header, Timeline, Focus).
- **`lib/ui/widgets/`**: Criação de novos widgets especializados (`TaskCard`, `GroupCard`, `CustomAvatar`).
- **`pubspec.yaml`**: Adição de dependências visuais (`google_fonts`, `flutter_svg`, `easy_date_timeline`).
