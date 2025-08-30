locals {
  casc_config = {
    appearance = {
      pipelineGraphView = {
        showGraphOnBuildPage = true
        showGraphOnJobPage   = true
      }
      themeManager = {
        disableUserThemes = false
        theme             = "dark"
      }
    }
    credentials = {
      system = {
        domainCredentials = [
          {
            credentials = [
              {
                string = {
                  scope       = "GLOBAL"
                  id          = "MINIO_ENDPOINT"
                  secret      = "http://192.168.1.100:9000"
                  description = "Minio Endpoint"
                }
              },
              {
                string = {
                  scope       = "GLOBAL"
                  id          = "MINIO_ACCESS_KEY"
                  secret      = "yjBwkhrm6HIyuptyq9p5"
                  description = "Minio Access Key"
                }
              },
              {
                string = {
                  scope       = "GLOBAL"
                  id          = "MINIO_SECRET_KEY"
                  secret      = "XCtPnMaCEDknilFmytugOffw5c2VKnIcSOgGn0oa"
                  description = "Minio Secret Key"
                }
              },
              {
                string = {
                  scope       = "GLOBAL"
                  id          = "MINIO_CONFIG_BUCKET"
                  secret      = "config"
                  description = "Minio Config Bucket"
                }
              },
              {
                string = {
                  scope       = "GLOBAL"
                  id          = "MINIO_TERRAFORM_BUCKET"
                  secret      = "terraform"
                  description = "Minio Terraform Bucket"
                }
              },
              {
                string = {
                  scope       = "GLOBAL"
                  id          = "CLOUD_IMAGE_REPOSITORY_URL"
                  secret      = "https://cir.nodadyoushutup.com/"
                  description = "Cloud image repository url"
                }
              },
              {
                string = {
                  scope       = "GLOBAL"
                  id          = "CLOUD_IMAGE_REPOSITORY_APIKEY"
                  secret      = "S#nvhs89vher"
                  description = "Cloud image repository api key"
                }
              }
            ]
          }
        ]
      }
    }
    jenkins = {
      systemMessage = "Jenkins configured automatically by Jenkins Configuration as Code plugin\\n\\n"
      securityRealm = {
        local = {
          allowsSignup = false
          users = [
            {
              id       = "admin"
              password = "password"
            }
          ]
        }
      }
      authorizationStrategy = {
        loggedInUsersCanDoAnything = {
          allowAnonymousRead = false
        }
      }
      numExecutors = 0
      nodes = [
        {
          permanent = {
            name     = "terraform"
            remoteFS = "/home/jenkins"
            launcher = {
              inbound = {
                workDirSettings = {
                  disabled               = true
                  failIfWorkDirIsMissing = false
                  internalDir            = "remoting"
                  workDirPath            = "/tmp"
                }
              }
            }
          }
        },
        {
          permanent = {
            name     = "cloud-image"
            remoteFS = "/home/jenkins"
            launcher = {
              inbound = {
                workDirSettings = {
                  disabled               = true
                  failIfWorkDirIsMissing = false
                  internalDir            = "remoting"
                  workDirPath            = "/tmp"
                }
              }
            }
          }
        }
      ]
    }
    unclassified = {
      location = {
        url = "http://192.168.1.101:8080"
      }
    }
  }
}
