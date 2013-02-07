BEGIN {
    FS = " |:"
}

{
    timestamp = (($2 * 60 + $3) * 60 + $4) * 1000
}

/Throbber stop/ {
    throbber = timestamp
}

/runGecko/ {
    print build, "runGecko", timestamp - throbber
}

/chrome startup finished/ {
    print build, "chrome", timestamp - throbber
}
