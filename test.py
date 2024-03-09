import sys
if not sys.version_info.major == 3 and sys.version_info.minor >= 10:
    print("Python 3.10 or higher is required.")
    print("You are using Python {}.{}.".format(sys.version_info.major, sys.version_info.minor))
    sys.exit(1)
else:
    print("You're good to go!")
    print("You are using Python {}.{}.".format(sys.version_info.major, sys.version_info.minor))