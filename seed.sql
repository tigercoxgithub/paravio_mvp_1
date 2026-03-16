INSERT INTO accounts (id, name) VALUES
('a0000000-0000-0000-0000-000000000001', 'FlySussex');

INSERT INTO characters (id, account_id, name, slug, system_prompt, model) VALUES
('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Fly Sussex', 'flysussex',
'You are @flysussex, the AI assistant for Fly Sussex flying school in East Sussex, UK. You help customers book flying lessons, check weather conditions, and manage their bookings. You are friendly, professional, and knowledgeable about aviation. Always greet customers warmly and ask how you can help.',
'llama-3.3-70b-versatile');

INSERT INTO skills (id, character_id, name, slug, description, instructions) VALUES
('10000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Book Me In', 'book_me_in',
'Book flying lessons and manage appointments',
'When a customer wants to book a lesson: 1) Check availability first using check_availability. 2) Confirm the date, time and instructor with the customer. 3) Use book_appointment to finalize. For cancellations, use cancel_booking. Always confirm details before booking.'),

('10000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'Weather Forecast', 'weather_forecast',
'Check weather conditions for flying',
'When asked about weather: Use get_weather to fetch current conditions. If conditions are unsuitable for flying (wind > 25 knots, visibility < 5km, heavy rain), warn the customer and suggest rescheduling. Always mention wind speed, visibility, and cloud base.'),

('10000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 'Manage Customers', 'manage_customers',
'Look up and manage customer records',
'Use lookup_customer to find customer details. Use update_customer to modify records. Always verify customer identity before sharing personal information.');

INSERT INTO skill_tools (id, skill_id, name, description, parameters_schema) VALUES
-- book_me_in tools
('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'check_availability',
'Check available lesson slots for a given date',
'{"type":"object","properties":{"date":{"type":"string","description":"Date to check (YYYY-MM-DD)"},"instructor":{"type":"string","description":"Optional instructor name"}},"required":["date"]}'),

('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'book_appointment',
'Book a flying lesson appointment',
'{"type":"object","properties":{"date":{"type":"string","description":"Date (YYYY-MM-DD)"},"time":{"type":"string","description":"Time (HH:MM)"},"student_name":{"type":"string","description":"Student name"},"instructor":{"type":"string","description":"Instructor name"},"lesson_type":{"type":"string","enum":["trial","standard","advanced","checkout"],"description":"Type of lesson"}},"required":["date","time","student_name","lesson_type"]}'),

('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'cancel_booking',
'Cancel an existing booking',
'{"type":"object","properties":{"booking_id":{"type":"string","description":"The booking ID to cancel"},"reason":{"type":"string","description":"Reason for cancellation"}},"required":["booking_id"]}'),

-- weather_forecast tools
('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002', 'get_weather',
'Get current weather conditions for the airfield',
'{"type":"object","properties":{"location":{"type":"string","description":"Airfield ICAO code or location name","default":"EGKA"}},"required":[]}'),

('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', 'get_forecast',
'Get weather forecast for upcoming days',
'{"type":"object","properties":{"location":{"type":"string","description":"Airfield ICAO code","default":"EGKA"},"days":{"type":"number","description":"Number of days to forecast (1-5)","default":3}},"required":[]}'),

-- manage_customers tools
('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000003', 'lookup_customer',
'Look up a customer by name or email',
'{"type":"object","properties":{"query":{"type":"string","description":"Customer name or email to search"}},"required":["query"]}'),

('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000003', 'update_customer',
'Update a customer record',
'{"type":"object","properties":{"customer_id":{"type":"string","description":"Customer ID"},"fields":{"type":"object","description":"Fields to update (name, email, phone, notes)"}},"required":["customer_id","fields"]}');
