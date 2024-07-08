/* Cleaning the data in SQL queries*/
-- Standardize Date Format
Update [nashville housing].kaggle.[dbo.nashville]
SET SaleDate = CONVERT(Date, SaleDate);

-- Add columns for split address
ALTER TABLE [nashville housing].kaggle.[dbo.nashville]
ADD PropertySplitAddress Varchar(255),
    PropertySplitCity Varchar(255);

-- Populate Property Address Data
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [nashville housing].kaggle.[dbo.nashville] a
JOIN [nashville housing].kaggle.[dbo.nashville] b ON a.ParcelID = b.ParcelID AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Split PropertyAddress into separate columns
UPDATE [nashville housing].kaggle.[dbo.nashville]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Split OwnerAddress into separate columns
ALTER TABLE [nashville housing].kaggle.[dbo.nashville]
ADD OwnerSplitAddress Nvarchar(255),
    OwnerSplitCity Nvarchar(255),
    OwnerSplitState Nvarchar(255);

UPDATE [nashville housing].kaggle.[dbo.nashville]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Change Y and N to Yes and No in "Sold as Vacant" field
UPDATE [nashville housing].kaggle.[dbo.nashville]
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
                   END;

-- Remove Duplicates based on specified criteria
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM [nashville housing].kaggle.[dbo.nashville]
)
DELETE FROM RowNumCTE
WHERE row_num > 1;

-- Drop unused columns
ALTER TABLE [nashville housing].kaggle.[dbo.nashville]
DROP COLUMN OwnerAddress,
            TaxDistrict,
            PropertyAddress,
            SaleDate;