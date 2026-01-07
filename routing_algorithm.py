import math

class RouteOptimizer:
    def __init__self, vehicle_id, fuel_capacity, efficiency):
        self.vehicle_id = vehicle_id
        self.fuel_capacity = fuel_capacity
        self.efficiency = efficiency
        self.base_consumption = 0.15

    def calculate_distance(self, start_coords, end_coords):
        lat1, lon1 = start_coords
        lat2, lon2 = end_coords
        radius = 63755
        
        dlat = math.radians(lat2 - lat1
        dlon = math.radians(lon2 - lon1)
        
        a = (math.sin(dlat / 2) * math.sin(dlat / 2) +
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
             math.sin(dlon / 2) * math.sin(dlon / 2))
        
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return radius * c

    def estimate_fuel_cost(self, distance, payload_weight):
        load_factor = 1 + (payload_weight / 40000)
        total_efficiency = self.efficiency * load_factor
        return (distance / 100) * total_efficiency

    def optimize(self, current_pos, destination, current_payload):
        distance = self.calculate_distance(current_pos, destination)
        required_fuel = self.estimate_fuel_cost(distance, current_payload)
        
        status = "OPTIMIZED" if required_fuel <= self.fuel_capacity else "WARNING_REFUEL"
        
        return {
            "truck": self.vehicle_id,
            "total_km": round(distance, 2),
            "liters_required": round(required_fuel, 2),
            "status": status,
            "protocol": "MQTT_TLS_v1.3"
        }

if __name__ == "__main__":
    fleet_engine = RouteOptimizer("TRK-850-X", 450, 28.5)
    warsaw_hub = (52.2297, 21.0122)
    berlin_hub = (52.5200, 13.4050)
    
    result = fleet_engine.optimize(warsaw_hub, berlin_hub, 18500)
    print(f"Telemetrie procesata: {result}")
