getQABits <- function(image, qa) {
  # Convert binary (character) to decimal (little endian)
  qa <-
    sum(2 ^ (which(rev(
      unlist(strsplit(as.character(qa), "")) == 1
    )) - 1))
  # Return a mask band image, giving the qa value.
  image$bitwiseAnd(qa)$lt(1)
}


mod13q1_clean <- function(img) {
  # Extract the NDVI band
  ndvi_values <- img$select("NDVI")
  
  # Extract the quality band
  ndvi_qa <- img$select("SummaryQA")
  
  # Select pixels to mask
  quality_mask <- getQABits(ndvi_qa, "11")
  
  # Mask pixels with value zero.
  ndvi_values$updateMask(quality_mask)
}