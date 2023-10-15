output "api_endpoints" {
  value = {
    add_endpoint         = "${aws_apigatewayv2_api.users_api.api_endpoint}/add",
    get_all_endpoint     = "${aws_apigatewayv2_api.users_api.api_endpoint}/getall",
    get_by_name_endpoint = "${aws_apigatewayv2_api.users_api.api_endpoint}/getbyid/{name}",
    delete_endpoint      = "${aws_apigatewayv2_api.users_api.api_endpoint}/delete/{userId}"
  }
}
output "website_url" {
  value = "http://${aws_s3_bucket.website.website_endpoint}"
}