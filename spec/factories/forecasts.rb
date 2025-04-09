FactoryBot.define do
  factory :forecast do
    address { "Seattle, WA 98101" }
    zip_code { "98101" }
    current_temp { 52.5 }
    high_temp { 58.0 }
    low_temp { 48.0 }
    conditions { "partly cloudy" }
    extended_forecast { '[{"date":"2025-04-08","day_name":"Tuesday","high":55,"low":46,"conditions":["partly cloudy"]}]' }
    queried_at { Time.current }
    
    trait :old do
      queried_at { 2.hours.ago }
    end
    
    trait :fresh do
      queried_at { 30.seconds.ago }
    end
    
    trait :cached do
      queried_at { 15.minutes.ago }
    end
    
    trait :seattle do
      address { "Seattle, WA 98101" }
      zip_code { "98101" }
      current_temp { 52.5 }
      high_temp { 58.0 }
      low_temp { 48.0 }
      conditions { "partly cloudy" }
    end
    
    trait :chicago do
      address { "Chicago, IL 60601" }
      zip_code { "60601" }
      current_temp { 45.0 }
      high_temp { 50.0 }
      low_temp { 40.0 }
      conditions { "windy" }
    end
    
    trait :new_york do
      address { "New York, NY 10001" }
      zip_code { "10001" }
      current_temp { 62.0 }
      high_temp { 68.0 }
      low_temp { 55.0 }
      conditions { "sunny" }
    end
  end
end
