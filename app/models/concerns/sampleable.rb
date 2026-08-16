module Sampleable
  extend ActiveSupport::Concern

  class_methods do
    def sample_body(category)
      public_send(category).sample&.body
    end

    def bodies_by_category
      all.group_by { |record| record.category.to_sym }
         .transform_values { |records| records.map(&:body) }
    end
  end
end
