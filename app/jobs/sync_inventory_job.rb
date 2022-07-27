class SyncInventoryJob < ApplicationJob
  queue_as :searchkick

  def perform(model)
    model.try(:sync_inventory)
  end

end
