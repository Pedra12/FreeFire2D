# FreeFire 3D Prototype

Projeto independente em Godot 4.3, orientado para Android em paisagem e jogabilidade 3D em terceira pessoa. A branch `main` e o protótipo 2D original permanecem preservados; todo o trabalho 3D fica nesta pasta e na branch `rebuild-3d`.

## Sistemas implementados
- Personagem 3D com câmera em terceira pessoa, mira aproximada e controle por toque.
- Movimento, corrida, salto, recarga, disparo contínuo e poses procedurais de braços e pernas.
- Quatro classes de arma: rifle, pistola, escopeta e submetralhadora, com dano, cadência e reservas independentes.
- Colete com absorção de dano, mochila com aumento de reservas, kits médicos e caixas de munição.
- Bots com perseguição, verificação de linha de visão, disparos, animação simples e queda ao serem eliminados.
- Zona segura que diminui ao longo da partida e causa dano fora dos limites.
- Construções com paredes segmentadas, entradas e espaços internos acessíveis.
- Terreno, estradas, árvores, objetos de cenário e veículos estacionados.
- HUD com vida, colete, munição, inimigos restantes, zona segura e estado da partida.
- Fluxos de CI separados para importar/testar o projeto 3D e exportar o APK Android.

## Limitações que continuam abertas
Este é um protótipo jogável de sistemas, não um jogo completo nem uma cópia visual de Free Fire. Os personagens, armas, veículos, árvores e construções ainda são montados com malhas primitivas do Godot. As poses e quedas são animações procedurais simples, não animações profissionais capturadas ou rigadas.

Ainda são necessários:
- Modelos 3D externos de qualidade para personagens, armas, veículos e cenário, com rig, materiais e licenças compatíveis.
- Animações completas e integradas a um esqueleto: idle, corrida, salto, mira, tiro, recarga, troca de arma e morte.
- Mapa maior com interiores mobiliados, escadas, andares, cobertura, colisões e pontos de interesse.
- Veículos dirigíveis, inventário completo, acessórios, diferentes níveis de armadura e balanceamento de loot.
- Áudio de armas, passos, ambiente, interface e efeitos sonoros; efeitos visuais de tiro, impacto, fumaça e explosões.
- Perfil de desempenho em aparelhos Android reais, ajuste de resolução, sombras, LOD, memória e taxa de quadros.
- Testes prolongados de partidas contra bots e correção de bugs antes de iniciar a arquitetura de multiplayer online.

## Ordem de desenvolvimento
1. Estabilizar importação, execução e exportação Android.
2. Testar em aparelho real e corrigir controles, desempenho, colisões e balanceamento dos bots.
3. Integrar assets 3D e animações licenciados, substituindo as malhas temporárias.
4. Completar mapa, inventário, áudio e efeitos.
5. Só então projetar multiplayer online com servidor autoritativo, sincronização, salas e proteção contra trapaças.

## Abrir e exportar
Importe esta pasta no Godot 4.3 pelo arquivo `project.godot`. O preset Android exporta para ARM64. A compilação Android precisa concluir o fluxo de CI e o APK precisa ser instalado e testado em aparelho real antes de ser considerado pronto.
