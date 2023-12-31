#' Assign gRNAs to cells
#'
#' @param mudata A MuData object
#' @param method A string indicating the method to use for assigning gRNAs
#' ("maximum", "thresholding", or "mixture"). See `sceptre::assign_grnas()` for details.
#' @param ... Additional parameters passed to `sceptre::assign_grnas()`. See `sceptre::assign_grnas()` for details.
#'
#' @return A MuData object with sceptre gRNA assignments added as a new experiment called "grna_assignment"
#' @export
#'
#' @examples
#' library(sceptreIGVF)
#' # load sample MuData
#' data(sample_mudata)
#' # assign gRNAs
#' mudata <- assign_grnas_sceptre(sample_mudata, method = "thresholding", threshold = 5)
#' mudata
assign_grnas_sceptre <- function(mudata, method, ...) {
  # convert MuData object to sceptre object
  sceptre_object <- convert_mudata_to_sceptre_object(mudata, include_covariates = FALSE)

  # set analysis parameters
  sceptre_object <- sceptre_object |>
   sceptre::set_analysis_parameters(
     discovery_pairs = data.frame(
       grna_target = character(0),
       response_id = character(0)
     )
   )

  # assign gRNAs
  sceptre_object <- sceptre_object |>
    sceptre::assign_grnas(method = method, ...)

  # extract sparse logical matrix of gRNA assignments
  grna_assignments <- sceptre_object@initial_grna_assignment_list
  grna_names <- names(grna_assignments)
  cell_barcodes <- colnames(sceptre_object@grna_matrix)
  j <- unlist(grna_assignments)
  p <- c(0, cumsum(sapply(grna_assignments, length)))
  num_rows <- length(grna_assignments)
  num_cols <- sceptre_object@grna_matrix |> ncol()
  grna_assignment_matrix <- Matrix::sparseMatrix(
    j = j,
    p = p,
    dims = c(num_rows, num_cols),
    dimnames = list(grna_names, cell_barcodes),
    x = rep(1, length(j))
  )

  # add sparse logical matrix to the MuData
  mudata <- add_matrix_to_mudata(
    new_matrix = grna_assignment_matrix,
    mudata = mudata,
    experiment_name = "grna_assignment"
  )

  # return MuData
  return(mudata)
}
