## 1. Estrutura de navegação

- [x] 1.1 Criar `MainShell` (Scaffold raiz) com bottom nav (Grupos/Calendário/Perfil)
- [x] 1.2 Conectar cada aba às respectivas telas (`GroupsScreen`, `HomeScreen`/Calendário, `ProfileScreen`)
- [x] 1.3 Preservar estado ao alternar abas (ex.: `IndexedStack`) e garantir seleção inicial consistente

## 2. Ajustes de layout e UX

- [x] 2.1 Remover/ajustar o acesso atual à tela de grupos no topo (que quebra o layout) e redirecionar para a aba **Grupos**
- [x] 2.2 Garantir que `GroupsScreen` seja renderizada dentro do layout padrão sem overlap/clipping (corrigir o bug do print)
- [x] 2.3 Remover a foto do usuário da `HomeScreen`.

## 3. Perfil (v1)

- [x] 3.1 Criar `ProfileScreen` (v1) exibindo avatar, nome e ação de logout (se disponível)
- [x] 3.2 Integrar `ProfileScreen` na bottom nav e validar navegação


## 4. Polimento básico

- [x] 4.1 Garantir que a área de conteúdo respeita a safe area e não conflita com a bottom nav
- [x] 4.2 Revisar labels/ícones e comportamento de back navigation para UX consistente
