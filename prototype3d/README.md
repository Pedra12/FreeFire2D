# FreeFire 3D Prototype

Projeto independente em Godot 4.3, orientado para Android em paisagem e jogabilidade 3D em terceira pessoa. A branch `main` e o protótipo 2D original permanecem preservados; todo o trabalho 3D fica nesta pasta e nesta branch.

## Sistemas já implementados no protótipo
- Personagem 3D com câmera traseira em perspectiva de ombro.
- Movimento por controles virtuais, corrida e rotação da câmera por arrasto.
- Modo de mira com aproximação da câmera.
- Disparo contínuo ao segurar o botão, recarga e munição.
- Alternância entre rifle e pistola, com reservas separadas.
- Bots inimigos com perseguição, linha de visão e disparos.
- Loot coletável de munição e kits médicos.
- HUD com vida, munição, arma selecionada, inimigos restantes e estado de vitória/derrota.
- Cenário 3D inicial com terreno, estradas, árvores e construções com colisão.

## Limitações atuais
Isto ainda é um protótipo de sistemas, não um jogo completo nem uma cópia visual de Free Fire. Os personagens, armas, árvores e construções ainda usam malhas primitivas temporárias. Ainda faltam modelos 3D de qualidade, animações, mapa detalhado com interiores, veículos, mais armas e itens, zona segura, áudio, efeitos, otimização e testes reais em aparelhos Android. O multiplayer online também não está implementado.

## Abrir e exportar
Importe esta pasta no Godot 4.3 pelo arquivo `project.godot`. O preset Android exporta para ARM64. A compilação Android precisa ser validada no fluxo de CI antes de considerar o APK pronto para instalação.
