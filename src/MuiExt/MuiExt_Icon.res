module Cloud = {
  module Normal = {
    @react.component @module("@material-ui/icons/CloudOutlined")
    external make: (~color: string=?, ~fontSize: string=?) => React.element = "default"
  }

  module Fail = {
    @react.component @module("@material-ui/icons/CloudOffOutlined")
    external make: (~color: string=?, ~fontSize: string=?) => React.element = "default"
  }

  module Success = {
    @react.component @module("@material-ui/icons/CloudDoneOutlined")
    external make: (~color: string=?, ~fontSize: string=?) => React.element = "default"
  }
}
