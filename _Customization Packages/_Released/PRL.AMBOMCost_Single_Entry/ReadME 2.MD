## Purpose:
Written to limit the result set of AMBOMCost table to 1 entry per BOM / Rev ID.

### 9/20/2024

Initial release.  Deploying a SQL view

### 10/1/2024

Per conversation with CJ, Jun recommends using an index on these SQL views, to ensure they will
work properly with repord designer.  

#### Dependancies:

Works only when manufacturing moudle is present, including AMBOMCost Table.


