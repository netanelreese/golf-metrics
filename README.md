# PyGolf
Python program to visualize all metrics about my golf game.
## Data
The data will be contained in `./data`
### Format
#### Game Entry
Each game entry will precede the individual hole entries for that game. The format is as follows:

| Field        | Data Type | Description                        | Example         |
|--------------|-----------|------------------------------------|-----------------|
| Course Name  | string    | Name of the golf course           | Pebble Beach    |
| Date         | string    | Date of the game (mmddyyyy)       | 04152024        |
| Total Score  | int       | Total strokes for the game        | 85              |
| Course Par   | int       | Total par for the course          | 72              |
| Tee Position | string    | Tee box used (white, blue, black) | Blue            |

#### Hole Entry
Each hole entry follows the game entry, with the format below:

| Field               | Data Type | Description                                 | Example |
|---------------------|-----------|---------------------------------------------|---------|
| Hole Number         | int       | The hole number (1-18)                      | 1       |
| Yardage             | int       | Distance of the hole in yards              | 420     |
| Hole Handicap       | int       | Hole handicap rating                       | 9       |
| Hole Par            | int       | Par value of the hole                      | 4       |
| Hole Score          | int       | Number of strokes taken on the hole        | 5       |
| Hit Fairway         | boolean   | Whether the fairway was hit (True/False)   | True    |
| Green in Regulation | boolean   | Whether green was reached in regulation    | False   |
| Number of Putts     | int       | Total putts taken on the hole              | 2       |

## Metrics
### Calculation
### Figures
