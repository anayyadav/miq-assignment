module "miq-test" {
  source              = "../modules/miq-test"
  name                = "${var.miq_test_name}"
  cidr                = "${var.miq_test_cidr}"
  public_subnets      = "${var.miq_test_public_subnets}"
  private_subnets     = "${var.miq_test_private_subnets}"
  tag_purpose         = "${var.miq_test_tag_purpose}"
  image               = "${var.miq_test_image}"
  root_volume_size    = "${var.miq_test_root_volume_size}"
  root_volume_type    = "${var.miq_test_root_volume_type}"
  type                = "${var.miq_test_type}"
  region              = "${var.miq_test_region}"
}