import wget
from pprint import pprint

with open('img_f.csv', 'w',encoding='utf-8') as f1:
    f1.write('model;name_file\n')
    with open('image_new.csv','r') as f:
        s=f.readlines()
        n=22818
        for str in s:
            try:
                wget.download(str.split(';')[1].strip().replace("'", ''), f'G:\photo\{n}.jpg')
                f1.write(str.split(';')[0].strip()+';'+f'{n}'+'\n')
                n+=1
            except Exception as e:
                print(f'''Не смогли скачать {str.split(';')[1].strip().replace("'", '')}''',e ,str, sep='\n')




# pprint(s[1].split(';')[0].strip())
# pprint(s[1].split(';')[1].strip().replace("'",''))
# wget.download(s[1].split(';')[1].strip().replace("'",''),'G:\photo\mest.jpg')

