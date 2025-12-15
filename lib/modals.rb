# Modal dialog windows - organized by context

require_relative 'modals/navigation'
require_relative 'modals/dialogs'
require_relative 'modals/file_operations'
require_relative 'modals/help'

module Sergeant
  module Modals
    include Navigation
    include Dialogs
    include FileOperations
    include Help
  end
end
