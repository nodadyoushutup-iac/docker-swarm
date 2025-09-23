locals {
  controller_url = "http://192.168.1.44:8080"

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
                  scope = "GLOBAL"
                  id = "CLOUD_IMAGE_REPOSITORY_URL"
                  secret = "https://cir.nodadyoushutup.com/"
                  description = "Cloud image repository url"
                }
              },
              {
                string = {
                  scope = "GLOBAL"
                  id = "CLOUD_IMAGE_REPOSITORY_APIKEY"
                  secret = "S#nvhs89vher"
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
            name     = "alpha"
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
            name     = "beta"
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
