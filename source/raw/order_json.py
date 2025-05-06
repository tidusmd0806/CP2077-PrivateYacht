import json
from collections import OrderedDict

def preserve_order_and_sort(original_json, new_json):
    def sort_json_by_order(original, target):
        if isinstance(original, dict) and isinstance(target, dict):
            sorted_dict = OrderedDict()
            for key in original:
                if key in target:
                    sorted_dict[key] = sort_json_by_order(original[key], target[key])
            return sorted_dict
        elif isinstance(original, list) and isinstance(target, list):
            return [
                sort_json_by_order(o, t) for o, t in zip(original, target) if isinstance(o, dict) and isinstance(t, dict)
            ]
        else:
            return target
    
    return sort_json_by_order(original_json, new_json)

# 元のJSONファイルを読み込み
with open('private_yacht//sectors//yacht_route.streamingsector.json', 'r', encoding='utf-8') as f:
    original_data = json.load(f, object_pairs_hook=OrderedDict)

# 新しいJSONファイルを読み込み
with open("D:\\SteamLibrary\\steamapps\\common\\Cyberpunk 2077\\bin\\x64\\plugins\\cyber_engine_tweaks\\mods\\PrivateYacht\\yacht_route.streamingsector.json", 'r', encoding='utf-8') as f:
    new_data = json.load(f)

# 元のJSONの順序に合わせて並び替え
sorted_json = preserve_order_and_sort(original_data, new_data)

# 並び替えたJSONを保存
with open('private_yacht//sectors//yacht_route.streamingsector.json', 'w', encoding='utf-8') as f:
    json.dump(sorted_json, f, ensure_ascii=False, indent=2)
