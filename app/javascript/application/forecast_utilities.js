// Utility functions for forecasts

export function get_forecast_days(forecast_list) {
  const days = [];
  const dayMap = new Map();
  
  forecast_list.forEach(item => {
    const date = new Date(item.dt * 1000);
    const dayKey = date.toISOString().split('T')[0];
    
    if (!dayMap.has(dayKey)) {
      dayMap.set(dayKey, {
        date: date,
        high_temp: item.main.temp_max,
        low_temp: item.main.temp_min,
        condition: item.weather[0].description,
        temps: [item.main.temp]
      });
    } else {
      const day = dayMap.get(dayKey);
      day.high_temp = Math.max(day.high_temp, item.main.temp_max);
      day.low_temp = Math.min(day.low_temp, item.main.temp_min);
      day.temps.push(item.main.temp);
    }
  });
  
  return Array.from(dayMap.values());
}

export function format_temp(temp, units) {
  if (units === 'imperial') {
    return Math.round((temp * 9/5) + 32) + '°F';
  } else {
    return Math.round(temp) + '°C';
  }
}
