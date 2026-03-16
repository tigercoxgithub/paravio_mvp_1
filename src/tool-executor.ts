interface ToolArgs {
  [key: string]: unknown;
}

const toolHandlers: Record<string, (args: ToolArgs) => string> = {
  check_availability(args) {
    const date = args.date as string;
    const instructor = (args.instructor as string) || "Any instructor";
    return JSON.stringify({
      date,
      instructor,
      available_slots: [
        { time: "09:00", instructor: "Captain Mike Harris", aircraft: "PA-28 Cherokee", duration: "1 hour" },
        { time: "11:00", instructor: "Sarah Thompson", aircraft: "Cessna 172", duration: "1 hour" },
        { time: "14:00", instructor: "Captain Mike Harris", aircraft: "PA-28 Cherokee", duration: "1.5 hours" },
        { time: "16:00", instructor: "James Wilson", aircraft: "Cessna 152", duration: "1 hour" },
      ],
    });
  },

  book_appointment(args) {
    const bookingId = `BK-${Date.now().toString(36).toUpperCase()}`;
    return JSON.stringify({
      success: true,
      booking_id: bookingId,
      date: args.date,
      time: args.time,
      student_name: args.student_name,
      instructor: args.instructor || "Assigned on day",
      lesson_type: args.lesson_type,
      aircraft: "PA-28 Cherokee",
      confirmation: `Booking ${bookingId} confirmed for ${args.student_name} on ${args.date} at ${args.time}. Please arrive 15 minutes early for your briefing.`,
    });
  },

  cancel_booking(args) {
    return JSON.stringify({
      success: true,
      booking_id: args.booking_id,
      reason: args.reason || "Customer requested",
      refund_status: "Full refund will be processed within 3-5 business days",
      confirmation: `Booking ${args.booking_id} has been cancelled. A full refund will be issued.`,
    });
  },

  get_weather(args) {
    const location = (args.location as string) || "EGKA";
    return JSON.stringify({
      location,
      station_name: "Shoreham Airport (EGKA)",
      timestamp: new Date().toISOString(),
      conditions: {
        temperature_c: 14,
        wind_speed_knots: 12,
        wind_direction: "SW (220°)",
        wind_gusts_knots: 18,
        visibility_km: 15,
        cloud_base_ft: 3500,
        cloud_cover: "SCT (scattered)",
        pressure_hpa: 1018,
        weather: "Fair",
        dewpoint_c: 8,
      },
      flying_assessment: {
        suitable_for_training: true,
        notes: "Good VFR conditions. Moderate south-westerly wind. Suitable for all experience levels.",
      },
    });
  },

  get_forecast(args) {
    const location = (args.location as string) || "EGKA";
    const days = (args.days as number) || 3;
    const forecast = [];
    const baseDate = new Date();

    for (let i = 0; i < days; i++) {
      const date = new Date(baseDate);
      date.setDate(date.getDate() + i);
      const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      forecast.push({
        date: date.toISOString().split("T")[0],
        day: dayNames[date.getDay()],
        conditions: i === 0
          ? { high_c: 15, low_c: 8, wind_knots: 12, visibility_km: 15, cloud_base_ft: 3500, summary: "Fair, moderate SW wind" }
          : i === 1
            ? { high_c: 13, low_c: 7, wind_knots: 22, visibility_km: 8, cloud_base_ft: 2000, summary: "Cloudy, stronger winds" }
            : { high_c: 16, low_c: 9, wind_knots: 8, visibility_km: 20, cloud_base_ft: 5000, summary: "Clear skies, light wind — excellent flying" },
        flying_suitable: i !== 1,
      });
    }

    return JSON.stringify({ location, station_name: "Shoreham Airport (EGKA)", forecast });
  },

  lookup_customer(args) {
    const query = (args.query as string) || "";
    return JSON.stringify({
      found: true,
      customer: {
        id: "CUST-00142",
        name: "Alex Morgan",
        email: "alex.morgan@email.com",
        phone: "+44 7700 900123",
        member_since: "2024-03-15",
        total_hours: 12.5,
        license_type: "Student Pilot",
        notes: "Working towards PPL. Prefers morning lessons. Allergic to cats (relevant for airport cat).",
        recent_bookings: [
          { id: "BK-PREV01", date: "2026-03-10", lesson_type: "standard", status: "completed" },
          { id: "BK-PREV02", date: "2026-03-17", lesson_type: "standard", status: "upcoming" },
        ],
      },
      search_query: query,
    });
  },

  update_customer(args) {
    const customerId = args.customer_id as string;
    const fields = args.fields as Record<string, unknown>;
    return JSON.stringify({
      success: true,
      customer_id: customerId,
      updated_fields: Object.keys(fields),
      message: `Customer ${customerId} updated successfully. Changed: ${Object.keys(fields).join(", ")}.`,
    });
  },
};

export function executeTool(name: string, args: ToolArgs): string {
  const handler = toolHandlers[name];
  if (!handler) {
    return JSON.stringify({ error: `Unknown tool: ${name}` });
  }
  return handler(args);
}
