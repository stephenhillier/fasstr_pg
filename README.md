# FASSTR as a Service

## Loading Hydat data

```
pgloader \
    --type sqlite \
    ./Hydat.sqlite3 \
    postgres://fasstr:test_pw@localhost:5432/fasstr
```
