provider "google" {
  credentials = "${file("mykubeadm-722d0b894033.json")}"
  project     = "mykubeadm"
  region      = "us-east1"
  zone      = "us-east1-b"
}

resource "google_compute_instance_template" "k8s_master_template" {
  name = "k8s-master-template"
  //machine_type = "g1-small"
  machine_type = "n1-standard-1"
  tags               = ["k8snodeport"]
  disk {
	source_image = "kubespinner"
	disk_type = "pd-standard"
  }
  network_interface {
    network = "default"
    access_config {
	network_tier = "STANDARD"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  metadata = {
    ssh-keys = "ansible:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "google_compute_instance_group_manager" "k8s_master" {
  name               = "k8s-master"
  instance_template  = "${google_compute_instance_template.k8s_master_template.self_link}"
  base_instance_name = "k8s-master"
  target_size        = "1"
}
resource "google_compute_instance_group_manager" "k8s_nodes" {
  name               = "k8s-node"
  instance_template  = "${google_compute_instance_template.k8s_master_template.self_link}"
  base_instance_name = "k8s-node"
  target_size        = "3"
}

resource "google_compute_instance" "k8s-jenkins" {
 name         = "k8s-jenkins"
 machine_type = "g1-small"
 tags = ["jenkins"]
 boot_disk {
   initialize_params {
     image = "kubespinner"
   }
 }
  network_interface {
    network = "default"
    access_config {
	network_tier = "STANDARD"
    }
  }

  metadata = {
    ssh-keys = "ansible:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "google_compute_firewall" "k8s-jenkins" {
 name    = "k8s-jenkins"
 network = "default"
 target_tags = ["jenkins"]
 source_ranges = ["0.0.0.0/0"]
 allow {
   protocol = "tcp"
   ports    = ["8080"]
 }
}

resource "google_compute_firewall" "k8s-nodeport" {
 name    = "k8s-nodeport"
 network = "default"
 target_tags = ["k8snodeport"]
 source_ranges = ["0.0.0.0/0"]
 allow {
   protocol = "tcp"
   ports    = ["30000-32767"]
 }
}

output "jenkins-ip" {
 value = "${google_compute_instance.k8s-jenkins.network_interface.0.access_config.0.nat_ip}"
}



