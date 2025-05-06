import json
import csv
import math

input_file = 'private_yacht/sectors/yacht_route.streamingsector.json'

def calculate_distance(point1, point2):
    return math.sqrt((point1['X'] - point2['X'])**2 + (point1['Y'] - point2['Y'])**2 + (point1['Z'] - point2['Z'])**2)

def parse_json_and_calculate_distances(json_data):
    nodes = json_data['Data']['RootChunk']['nodes']
    node_data = json_data['Data']['RootChunk']['nodeData']['Data']

    index = 0
    relative_distances = []
    absolute_positions = []

    for node in nodes:
        if len(node_data) <= index:
            break
        base_position = node_data[index]['Position']
        index = index + 1
        base_x, base_y, base_z = base_position['X'], base_position['Y'], base_position['Z']
        if node['Data']['$type'] == 'worldSpeedSplineNode':
            debug_name = node['Data']['debugName']['$value']
            spline_data = node['Data']['splineData']['Data']['points']
            accumulated_distance = 0
            previous_point = spline_data[0]['position']
            
            for point in spline_data:
                current_point = point['position']
                distance = calculate_distance(previous_point, current_point)
                accumulated_distance += distance
                absolute_x = base_x + current_point['X']
                absolute_y = base_y + current_point['Y']
                absolute_z = base_z + current_point['Z']
                relative_distances.append([debug_name, current_point['X'], current_point['Y'], current_point['Z'], accumulated_distance])
                absolute_positions.append([debug_name, absolute_x, absolute_y, absolute_z])
                previous_point = current_point

    return relative_distances, absolute_positions

def save_to_csv(data, output_file, headers):
    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        for row in data:
            writer.writerow(row)

# Read JSON
with open(input_file, 'r', encoding='utf-8') as file:
    json_data = json.load(file)

# Calculate accumulated distance and absolute positions
relative_distances, absolute_positions = parse_json_and_calculate_distances(json_data)

# Output to CSV
relative_output_file = 'relative_distances.csv'
absolute_output_file = 'absolute_positions.csv'
save_to_csv(relative_distances, relative_output_file, ['Debug Name', 'Relative X', 'Relative Y', 'Relative Z', 'Accumulated Distance'])
save_to_csv(absolute_positions, absolute_output_file, ['Debug Name', 'Absolute X', 'Absolute Y', 'Absolute Z'])
