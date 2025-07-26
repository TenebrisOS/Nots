# deco.py (simplified example)
class AnsiColors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    MAGENTA = '\033[95m'
    NC = '\033[0m' # No Color

green = AnsiColors.GREEN
yellow = AnsiColors.YELLOW
red = AnsiColors.RED
blue = AnsiColors.BLUE
cyan = AnsiColors.CYAN
magenta = AnsiColors.MAGENTA
nc = AnsiColors.NC
white= AnsiColors.NC

# For any other attributes your original deco might have used
def __getattr__(self, name):
    return "" # Default to empty string for missing attributes

# SYMBOLS
ask = green + '[' + white + '?' + green + '] '+ blue
success = yellow + '[' + white + '√' + yellow + '] '+green
error = blue + '[' + white + '!' + blue + '] '+red
info= yellow + '[' + white + '+' + yellow + '] '+ cyan
info2= green + '[' + white + '•' + green + '] '
nrml=nc
