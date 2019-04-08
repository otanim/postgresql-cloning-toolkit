# postgresql-cloning-toolkit

## Prerequisites  
Check both files: **./csv_to_database_migration.sh** and **./database_to_csv_caching.sh** and make sure that credentials for source and destination database are correct.  

## To copy cached database to PostgreSQL database
```bash
./csv_to_database_migration.sh
```

## To cache PostgreSQL database in local machine
```bash
./database_to_csv_caching.sh
```

## Toolkit structure
```
postgresql-cloning-toolkit
|_csv_to_database_migration.sh   | csv to PostgreSQL database migrator
|_database_to_csv_caching.sh     | PostgreSQL database to csv chacher
|_directory_generator.sh         | "tables" folder generator
|_table_list_full                | list of tables that needs to be fully copied
|_table_list_short               | list of tables that needs to be partially copied (by start and end day or document counts)
|_timing_tool.sh                 | small toolset to measure copying process
```


## FAQ

**Q:** I've receive "Permission denied" when I've tried to execute particular script.  
**A:** Execute `chmod u+x ./*.sh` inside of this project's folder.

**Q:** How to change credentials of source database and destination database?  
**A:** You can either run particular script with "--help" and see parameters how to define password, or if you know how to code in shell, change script's sources.