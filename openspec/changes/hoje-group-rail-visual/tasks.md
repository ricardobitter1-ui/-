## 1. Utilitários de cor e ícone



- [x] 1.1 Implementar função de **luminância relativa** (sRGB) e **cor de fundo normalizada** a partir do hex do grupo (escurecer/blend até texto branco ser legível)

- [x] 1.2 Centralizar parsing de hex num helper reutilizável (se ainda duplicado entre ecrãs), com fallback para Primary Blue

- [x] 1.3 Mapear `GroupModel.icon` (strings atuais do CRUD) → `IconData` com fallback `Icons.groups_rounded`



## 2. Componente visual do rail



- [x] 2.1 Refatorar `_buildGroupProgressRail` para usar fundo baseado na cor normalizada (gradiente opcional leve para profundidade)

- [x] 2.2 Adicionar **círculo de ícone** (fundo branco translúcido + ícone branco) no topo ou canto do card

- [x] 2.3 Ajustar tipografia: título branco w800; linha de stats branco com opacidade ~0.72; maxLines/ellipsis mantidos

- [x] 2.4 Ajustar `LinearProgressIndicator`: track/fill conforme design (Success Cyan ou branco — uma regra única documentada)

- [x] 2.5 Manter `InkWell`/toque e navegação para `GroupDetailScreen` inalterados em comportamento



## 3. QA e documentação



- [x] 3.1 Verificar visualmente **cada** cor do seletor atual de grupos + um hex inválido (fallback)

- [x] 3.2 Complementar `openspec/style_guide.md` com secção **“Group Rail Cards (aba Hoje)”** (superfície, contraste, ícone, progresso, sombra)

- [x] 3.3 `flutter analyze` / `flutter test` sem regressões

