# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

require 'date'

module Aws
  module Record
    module Attributes
      module DateMarshaler

        class << self

          def type_cast(raw_value, options = {})
            case raw_value
            when nil
              nil
            when ''
              nil
            when Date
              raw_value
            when Integer
              Date.parse(Time.at(raw_value).to_s) # assumed timestamp
            else
              Date.parse(raw_value.to_s) # Time, DateTime or String
            end
          end

          def serialize(raw_value, options = {})
            date = type_cast(raw_value)
            if date.nil?
              nil
            elsif date.is_a?(Date)
              date.strftime('%Y-%m-%d')
            else
              raise ArgumentError, "expected a Date value or nil, got #{date.class}"
            end
          end

        end

      end
    end
  end
end
