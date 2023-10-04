import pygame as py
import ChessEngine

py.init()
WIDTH = 512
HEIGHT = 512
DIMENSION = 8
SQ_SIZE = HEIGHT // DIMENSION
HIGHLIGHT_COLOR = (0, 255, 0)
VALID_MOVES_COLOR = (0, 0, 255)
HIGHLIGHT_ALPHA = 84  # transparency
VALID_MOVES_ALPHA = 84
highlight_surface = py.Surface((SQ_SIZE, SQ_SIZE), py.SRCALPHA)
highlight_surface.fill((HIGHLIGHT_COLOR[0], HIGHLIGHT_COLOR[1], HIGHLIGHT_COLOR[2], HIGHLIGHT_ALPHA))
valid_moves_surface = py.Surface((SQ_SIZE, SQ_SIZE), py.SRCALPHA)
valid_moves_surface.fill((VALID_MOVES_COLOR[0], VALID_MOVES_COLOR[1], VALID_MOVES_COLOR[2], VALID_MOVES_ALPHA))
MAX_FPS = 15
IMAGES = {}


# Initialize a global dictionary of images


def loadImages():
    pieces = ['wP', 'wR', 'wN', 'wB', 'wQ', 'wK',
              'bP', 'bR', 'bN', 'bB', 'bQ', 'bK']

    for piece in pieces:
        IMAGES[piece] = py.transform.scale(py.image.load(
            "Pieces/" + piece + ".png"), (SQ_SIZE, SQ_SIZE))


def main():
    screen = py.display.set_mode((WIDTH, HEIGHT))
    clock = py.time.Clock()
    screen.fill(py.Color("white"))
    gameState = ChessEngine.GameState()
    validMoves = gameState.getValidMoves()
    moveMade = False
    sqSelected = ()
    playerClicks = []
    loadImages()
    running = True

    while running:
        for e in py.event.get():
            if e.type == py.QUIT:
                running = False

            # Mouse Handlers
            elif e.type == py.MOUSEBUTTONDOWN:
                location = py.mouse.get_pos()
                col = location[0] // SQ_SIZE
                row = location[1] // SQ_SIZE

                if sqSelected == (row, col):
                    sqSelected = ()
                    playerClicks = []
                else:
                    sqSelected = (row, col)
                    playerClicks.append(sqSelected)
                if len(playerClicks) == 2:
                    move = ChessEngine.Move(
                        playerClicks[0], playerClicks[1], gameState.board)
                    if move in validMoves:
                        gameState.makeMove(move)
                        moveMade = True
                        sqSelected = ()
                        playerClicks = []
                    else:
                        playerClicks = [sqSelected]

            # Key Handlers
            elif e.type == py.KEYDOWN:
                if e.key == py.K_z:
                    gameState.undoMove()
                    moveMade = True

        if moveMade:
            validMoves = gameState.getValidMoves()
            moveMade = False

        py.display.set_caption("Chess!")
        drawGameState(screen, gameState, sqSelected, validMoves)
        clock.tick(MAX_FPS)
        py.display.flip()


def highlightPiece(screen, sqSelected):
    if sqSelected:
        r, c = sqSelected
        screen.blit(highlight_surface, (c * SQ_SIZE, r * SQ_SIZE))


def showValidMoves(screen, validMoves, sqSelected):
    if validMoves and sqSelected:
        for move in validMoves:
            if move.startRow == sqSelected[0] and move.startCol == sqSelected[1]:  # From the Valid Moves give me only
                # the valid move of the selected piece
                r, c = move.endRow, move.endCol
                screen.blit(valid_moves_surface, (c * SQ_SIZE, r * SQ_SIZE))


def drawGameState(screen, gameState, sqSelected, validMoves):
    drawBoard(screen)
    drawPieces(screen, gameState.board)
    highlightPiece(screen, sqSelected)
    showValidMoves(screen, validMoves, sqSelected)


def drawBoard(screen):
    colors = [py.Color("beige"), py.Color("dark red")]
    for rows in range(DIMENSION):
        for cols in range(DIMENSION):
            color = colors[(rows + cols) % 2]
            py.draw.rect(screen, color, py.Rect(
                cols * SQ_SIZE, rows * SQ_SIZE, SQ_SIZE, SQ_SIZE))


def drawPieces(screen, board):
    for rows in range(DIMENSION):
        for cols in range(DIMENSION):
            piece = board[rows][cols]
            if piece != "--":
                screen.blit(IMAGES[piece], py.Rect(
                    cols * SQ_SIZE, rows * SQ_SIZE, SQ_SIZE, SQ_SIZE))


if __name__ == "__main__":
    main()
