use housing;

# Cleaning data 

describe housing_data; 

-- update empty property address for NULL

UPDATE housing_data 
SET 
    PropertyAddress = null
WHERE
    PropertyAddress = '';

SELECT -- check the result
    PropertyAddress
FROM
    housing_data
WHERE
    PropertyAddress is null;

commit; -- commit if success

rollback; -- rollback if not

-- looking for address with empty data
SELECT 
    h1.ParcelId,
    h1.PropertyAddress,
    h2.ParcelId,
    h2.PropertyAddress,
    IFNULL(h1.PropertyAddress, h2.PropertyAddress)
FROM
    housing_data h1
        JOIN
    housing_data h2 ON h1.ParcelID = h2.ParcelID
        AND h1.UniqueID != h2.UniqueID
WHERE
    h1.PropertyAddress IS NULL;

-- updating data in empty rows

update housing_data h1
        JOIN
    housing_data h2 ON h1.ParcelID = h2.ParcelID
        AND h1.UniqueID != h2.UniqueID
set h1.PropertyAddress = IFNULL(h1.PropertyAddress, h2.PropertyAddress)
WHERE
    h1.PropertyAddress IS NULL;
    
commit; -- commit if success

rollback; -- rollback if not

SELECT -- spliting property address for street and city
    PropertyAddress,
    substring(PropertyAddress, 1, locate(',', PropertyAddress)-1) as Address,
	substring(PropertyAddress, locate(',', PropertyAddress)+1) as City
FROM
    housing_data;

-- add new columns with spliting address
    
alter table housing_data
add Address char(255),
add City char(255);

UPDATE housing_data 
SET 
    Address = SUBSTRING(PropertyAddress,
        1,
        LOCATE(',', PropertyAddress) - 1),
    City = SUBSTRING(PropertyAddress,
        LOCATE(',', PropertyAddress) + 1);

SELECT 
    *
FROM
    housing_data
LIMIT 100;

commit; -- commit if success

rollback; -- rollback if not

-- spliting owner address for street,city and state
-- first replace empty rows for NULL

UPDATE housing_data 
SET 
    OwnerAddress = REPLACE(OwnerAddress, '', NULL)
WHERE
    OwnerAddress = '';

-- test query for result
SELECT 
    OwnerAddress,
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerAddress,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2),
            ',',
            - 1) AS OwnerCity,
    SUBSTRING_INDEX(OwnerAddress, ',', - 1) AS OwnerState
FROM
    housing_data;
    
-- add columns to the table

alter table housing_data
add OwnerStreet char(255),
add OwnerCity char(255),
add OwnerState char(255);

UPDATE housing_data 
SET 
    OwnerStreet = SUBSTRING_INDEX(OwnerAddress, ',', 1),
    OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2),
            ',',
            - 1),
    OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', - 1);
    
select *
from housing_data;

commit; -- commit if success

rollback; -- rollback if not

-- Change Y/N to Yes/No in SoldAsVacant
SELECT DISTINCT
    SoldAsVacant, COUNT(SoldAsVacant)
FROM
    housing_data
GROUP BY SoldAsVacant;

UPDATE housing_data 
SET 
    SoldAsVacant = CASE
        WHEN SoldAsVacant = 'N' THEN 'No'
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        ELSE SoldAsVacant
    END;

commit; -- commit if success

rollback; -- rollback if not

-- Remove duplicates
SELECT 
    *
FROM
    housing_data;

-- find duplicates 
/* maybe I did something wrong but lose connection when trying to delete using CTE
with DupNumCTE as(
SELECT 
    uniqueid, 
    row_number() over(partition by parcelid, propertyaddress, saledate, saleprice, legalreference order by uniqueid) as duplicates
FROM
    housing_data)
select *  from dupnumcte
where duplicates > 1;
#delete from housing_data
#where uniqueid in (select uniqueid from dupnumcte where duplicates > 1);
*/

-- now it works
create temporary table DupID
	with DupNumCTE as(
		SELECT 
			uniqueid, 
			row_number() over(partition by parcelid, propertyaddress, saledate, saleprice, legalreference order by uniqueid) as duplicates
		FROM
			housing_data)
select *  from dupnumcte
where duplicates > 1;

select * from dupid;

delete from housing_data
where uniqueid in (select uniqueid from dupid);

commit; -- commit if success

rollback; -- rollback if not

-- delete unused columns

describe housing_data;

alter table housing_data
drop column propertyaddress,
drop column taxdistrict,
drop column owneraddress; 
