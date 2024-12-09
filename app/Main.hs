import Graphics.Gloss
import Graphics.Gloss.Interface.Pure.Game
import System.Random
import Data.List (transpose, permutations)




-- Define the game state
data GameState = GameState
  { board      :: [[Int]]
  , score      :: Int
  , bestScore  :: Int  -- New field for best score
  , gen        :: StdGen
  , difficulty :: String
  , menuShown  :: Bool
  , timer      :: Float
  }


-- Function to set the initial grid size based on difficulty
initialGridSize :: String -> Int
initialGridSize difficulty =
  case difficulty of
    "easy"   -> 4
    "medium" -> 5
    "hard"   -> 6
    _        -> error "Invalid difficulty"

-- Initial game state with a specified grid size
initialState :: GameState
initialState = GameState
  { board      = replicate (initialGridSize "easy") (replicate (initialGridSize "easy") 0)
  , score      = 0
  , bestScore  = 0  -- Initialize best score to 0
  , gen        = mkStdGen 0
  , difficulty = "easy"
  , menuShown  = True
  , timer      = 0
}

-- Function to render the game
render :: GameState -> Picture
render game
  | menuShown game = renderDifficultyMenu game  -- Render difficulty menu if menu is shown
  | isGameOver game = renderGameOver game  -- Render game over screen
  | otherwise = renderGame game  -- Render the game

drawTextSmall :: String -> Float -> Float -> Picture
drawTextSmall textString x y = translate x y $ scale 0.2 0.2 $ color black $ text textString

-- Function to render the game over screen
renderGameOver :: GameState -> Picture
renderGameOver game
  | timer game < 3.0 = pictures
      [ drawText "Game Over!" (-150) (-300)
      , drawTextSmall ("Difficulty: " ++ difficulty game) (-450) 100
      , drawTextSmall ("Score: " ++ show (maximumTileValue (board game))) (-450) 50
      , drawTextSmall ("Best Score: " ++ show (bestScore game)) (-450) (-50)  -- Corrected y-coordinate
      , drawBoard (board game)
      ]
  | otherwise = renderDifficultyMenu game


restartGame :: GameState -> GameState
restartGame game =
  initialState { difficulty = difficulty game, menuShown = False, timer = 0, bestScore = bestScore game }  -- Keep best score when restarting


-- Function to render the difficulty menu
renderDifficultyMenu :: GameState -> Picture
renderDifficultyMenu game = pictures
  [ drawText "Choose Difficulty:" (-150) 150
  , drawText "1. Easy" (-150) 50
  , drawText "2. Medium" (-150) 0
  , drawText "3. Hard" (-150) (-50)
  , drawText "Welcome to 2048 Game!" (-250) 220
  ]

-- Function to render the game with initial text for difficulty level
-- Function to render the game with initial text for difficulty level
renderGame :: GameState -> Picture
renderGame game = pictures
  [ drawTextSmall ("Difficulty: " ++ difficulty game) (-450) 100
  , drawTextSmall ("Score: " ++ show (score game)) (-450) 50
  , drawTextSmall ("Menu (M)" ) (-450) 0  -- Display "Menu" when menu is active
  , drawTextSmall ("New Game (R)" ) (-450) (-50)  
  ,drawTextSmall ("Best Score: " ++ show (bestScore game)) (-450) (-100)  -- Corrected y-coordinate
  , drawBoard (board game)
  ]



drawBoard :: [[Int]] -> Picture
drawBoard board = pictures $ concat
    [ [ drawTile x y val | (x, val) <- zip [0..] row] | (y, row) <- zip [0..] board]

-- Function to render a single tile
drawTile :: Int -> Int -> Int -> Picture
drawTile x y val =
  translate (fromIntegral x * 100 - 150) (fromIntegral y * 100 - 150) $
    pictures
      [ color (tileColor val) $ rectangleSolid 90 90
      , translate (-20) (-20) $ scale 0.2 0.2 $ color (tileTextColor val) $ text (show val)
      ]

-- Function to determine the color of a tile based on its value
tileColor :: Int -> Color
tileColor val = case val of
  0    -> greyN 0.9
  2    -> light (light (light blue))
  4    -> light (light blue)
  8    -> light blue
  16   -> light (light (light green))
  32   -> light (light green)
  64   -> light green
  128  -> light (light (light red))
  256  -> light (light red)
  512  -> light red
  1024 -> light (light (light violet))
  2048 -> light (light violet)
  _    -> red -- Add a wildcard pattern for all other cases; you can choose any color or handle it as needed

-- Function to determine the text color of a tile based on its value
tileTextColor :: Int -> Color
tileTextColor val
  | val >= 16 = white
  | otherwise = black

-- Function to draw text on the screen
drawText :: String -> Float -> Float -> Picture
drawText textString x y = translate x y $ scale 0.3 0.3 $ color black $ text textString

handleInput :: Event -> GameState -> GameState
handleInput e game =
  case e of
    EventKey (Char '1') Down _ _ -> startGame "easy" game
    EventKey (Char '2') Down _ _ -> startGame "medium" game
    EventKey (Char '3') Down _ _ -> startGame "hard" game
    EventKey (SpecialKey KeyUp) Down _ _ -> moveAndAddRandom moveDown game
    EventKey (SpecialKey KeyDown) Down _ _ -> moveAndAddRandom moveUp game
    EventKey (SpecialKey KeyLeft) Down _ _ -> moveAndAddRandom moveLeft game
    EventKey (SpecialKey KeyRight) Down _ _ -> moveAndAddRandom moveRight game
    EventKey (Char 'r') Down _ _ -> restartGame game  -- Handle restart option
    EventKey (Char 'm') Down _ _ -> goToMenu game
    _ -> game

-- Helper function to find the max value
maximumTileValue :: [[Int]] -> Int
maximumTileValue board = maximum (concat board)

-- Function to go back to the menu
goToMenu :: GameState -> GameState
goToMenu game =
  initialState { difficulty = difficulty game, menuShown = True, timer = 0, score = 0, bestScore = bestScore game, gen = mkStdGen 0 }  -- Keep best score when going to menu

-- Function to start the game with a chosen difficulty and set the grid size
startGame :: String -> GameState -> GameState
startGame chosenDifficulty game =
  game { difficulty = chosenDifficulty, board = replicate (initialGridSize chosenDifficulty) (replicate (initialGridSize chosenDifficulty) 0), menuShown = False, score = 0 } 

-- Function to update the game state
update :: Float -> GameState -> GameState
update dt game
  | menuShown game = game
  | isGameOver game = handleGameOver dt game
  | otherwise =
    let currentScore = maximumTileValue (board game)
        newBestScore = max (bestScore game) currentScore
    in
      if currentScore >= 2048
        then game { menuShown = True, bestScore = newBestScore }
        else game { bestScore = newBestScore }


handleGameOver :: Float -> GameState -> GameState
handleGameOver dt game
  | isGameOver game =
    let newTimer = timer game + dt
        newBestScore = max (bestScore game) (maximumTileValue (board game))  -- Update best score
    in if newTimer >= 3.0
      then goToMenu game { bestScore = newBestScore }  -- Pass updated best score to goToMenu
      else game { timer = newTimer, bestScore = newBestScore }
  | otherwise = game


-- Function to check if the game is over
isGameOver :: GameState -> Bool
isGameOver game = not (isPossibleMove game)
-- Helper functions for game logic
-- Helper function to move and add a random tile
moveAndAddRandom :: ([[Int]] -> [[Int]]) -> GameState -> GameState
moveAndAddRandom moveFn game =
  let
    newBoard = moveFn (board game)
    (emptyCells, newGen) = findEmptyCells game (gen game) (length (board game))
    
    -- Check if any movement occurred
    movementOccurred = newBoard /= (board game)
    
    -- Update the board only if movement occurred
    updatedBoard = if movementOccurred then newBoard else board game
    
    -- Choose a random empty cell for the new tile
    (x, y) = if null emptyCells then (0, 0) else head emptyCells
    
    -- Generate a new tile value (either 2 or 4)
    newValue = if head (randomRs (0, 1) newGen :: [Int]) == 0 then 2 else 4
    
    -- Update the board with the new tile
    finalBoard = updateTile x y newValue updatedBoard
    
    -- Update the score as the sum of all tile values
    updatedScore = sum (concat finalBoard)
    
    -- Update the best score if needed
    updatedBestScore = max (bestScore game) updatedScore
  in
    game { board = finalBoard, gen = newGen, menuShown = False, score = updatedScore, bestScore = updatedBestScore }




-- Helper function to calculate the score based on merged tiles
calculateMergedScore :: [[Int]] -> [[Int]] -> Int
calculateMergedScore oldBoard newBoard =
  sum [tileValue | (oldRow, newRow) <- zip oldBoard newBoard, (oldTile, newTile) <- zip oldRow newRow, newTile > oldTile, let tileValue = newTile]



  -- Helper function to check if there are empty spaces on the board
hasEmptySpaces :: [[Int]] -> Bool
hasEmptySpaces board = any (any (== 0)) board
  
-- Function to check if a move is possible based on game rules
isPossibleMove :: GameState -> Bool
isPossibleMove game =
      hasEmptySpaces (board game) ||
      hasAdjacentTiles (board game) ||
      any (not . isRowBlocked) (board game) ||
      any (not . isColumnBlocked) (transpose (board game))
  
  -- Helper function to check if there are adjacent tiles with the same value
hasAdjacentTiles :: [[Int]] -> Bool
hasAdjacentTiles board =
      any hasAdjacentTilesInRow board || any hasAdjacentTilesInRow (transpose board)
  
  -- Helper function to check if there are adjacent tiles with the same value in a row
hasAdjacentTilesInRow :: [Int] -> Bool
hasAdjacentTilesInRow row =
      any (\(x, y) -> x == y) (adjacentPairs row)
  
  -- Helper function to check if a row is blocked (no empty spaces and no adjacent tiles with the same value)
isRowBlocked :: [Int] -> Bool
isRowBlocked row =
      not (any (== 0) row || any (\(x, y) -> x == y) (adjacentPairs row))
  
  -- Helper function to check if a column is blocked (no empty spaces and no adjacent tiles with the same value)
isColumnBlocked :: [Int] -> Bool
isColumnBlocked = isRowBlocked

  -- Function to check if a move to the left is possible
canMoveLeft :: [[Int]] -> Bool
canMoveLeft board = any movePossibleLeft board
  
  -- Function to check if a move to the right is possible
canMoveRight :: [[Int]] -> Bool
canMoveRight board = any movePossibleRight board
  
  -- Function to check if a move up is possible
canMoveUp :: [[Int]] -> Bool
canMoveUp board = any movePossibleUp (transpose board)
  
  -- Function to check if a move down is possible
canMoveDown :: [[Int]] -> Bool
canMoveDown board = any movePossibleDown (transpose board)
  
  -- Helper function to check if a move to the left is possible in a row
movePossibleLeft :: [Int] -> Bool
movePossibleLeft row = any canMerge (adjacentPairs row)
  
  -- Helper function to check if a move to the right is possible in a row
movePossibleRight :: [Int] -> Bool
movePossibleRight row = movePossibleLeft (reverse row)
  
  -- Helper function to check if a move up is possible in a column
movePossibleUp :: [Int] -> Bool
movePossibleUp = movePossibleLeft
  
  -- Helper function to check if a move down is possible in a column
movePossibleDown :: [Int] -> Bool
movePossibleDown = movePossibleRight
  
  -- Helper function to check if there are adjacent pairs that can merge
canMerge :: (Int, Int) -> Bool
canMerge (x, y) = x == y && x /= 0
  
  -- Helper function to generate adjacent pairs in a list
adjacentPairs :: [a] -> [(a, a)]
adjacentPairs [] = []
adjacentPairs [_] = []
adjacentPairs (x:y:xs) = (x, y) : adjacentPairs (y:xs)
  
findEmptyCells :: GameState -> StdGen -> Int -> ([(Int, Int)], StdGen)
findEmptyCells game gen gridSize =
  case randomElem emptyCells gen of
    Just (selectedCell, newGen) -> ([selectedCell], newGen)
    Nothing -> ([], gen)  -- Handle the case when the list is empty
  where
    indices = [(x, y) | x <- [0..gridSize-1], y <- [0..gridSize-1]]
    emptyCells = filter (\(x, y) -> (board game !! y !! x) == 0) indices
    shuffledCells = head (permutations emptyCells)

  
  -- Helper function to get a random element from a list
randomElem :: [a] -> StdGen -> Maybe (a, StdGen)
randomElem [] gen = Nothing
randomElem list gen =
    let (index, newGen) = randomR (0, length list - 1) gen
    in Just (list !! index, newGen)
  
  

updateTile :: Int -> Int -> Int -> [[Int]] -> [[Int]]
updateTile x y val board =
  take y board ++
  [take x (board !! y) ++ [val] ++ drop (x + 1) (board !! y)] ++
  drop (y + 1) board


moveLeft :: [[Int]] -> [[Int]]
moveLeft = map moveRowLeft

moveRowLeft :: [Int] -> [Int]
moveRowLeft row = mergedRow ++ replicate (length row - length mergedRow) 0
  where
    mergedRow = mergeRow $ filter (/= 0) row

moveRowRight :: [Int] -> [Int]
moveRowRight row = replicate (length row - length mergedRow) 0 ++ mergedRow
      where
        mergedRow = mergeRow $ filter (/= 0) (reverse row)

mergeRow :: [Int] -> [Int]
mergeRow [] = []
mergeRow [x] = [x]
mergeRow (x1 : x2 : xs)
  | x1 == x2 = x1 * 2 : mergeRow xs
  | otherwise = x1 : mergeRow (x2 : xs)
    


moveRight :: [[Int]] -> [[Int]]
moveRight = map (reverse . moveRowLeft . reverse)

moveUp :: [[Int]] -> [[Int]]
moveUp board = transpose $ map moveRowUp $ transpose board

moveDown :: [[Int]] -> [[Int]]
moveDown = transpose . map moveRowDown . transpose

moveRowUp :: [Int] -> [Int]
moveRowUp row = mergedRow ++ replicate (length row - length mergedRow) 0
  where
    mergedRow = mergeRow $ filter (/= 0) row

moveRowDown :: [Int] -> [Int]
moveRowDown row = replicate (length row - length mergedRow) 0 ++ mergedRow
      where
        mergedRow = mergeRow $ filter (/= 0) (reverse row)

main :: IO ()
main = do
  putStrLn "Welcome to 2048 Game!"
  let windowSize = 900
      bgColor = makeColorI 240 248 255 255  -- RGB (240, 248, 255) with full opacity

  play (InWindow "2048 Game" (windowSize, windowSize) (10, 10)) bgColor 30 initialState render handleInput update
