from lxml import etree
import wget
class load_matrix_yml():
    def __init__(self,f_name):
        self.f_name=f_name
        self.tree = etree.parse(self.f_name)
    def get_all_data_files(self):
        products, images, atributs =self.__get_products()
        # Запишем файл с продукцией
        with open('products.csv', 'w',encoding='utf-8') as f:
            f.write('model' + ';')
            f.write('name' + ';')
            f.write('quantity' + ';')
            f.write('manufacturer' ';')
            f.write('min' + ';')
            f.write('price' + ';')
            f.write('categoryId' + ';')
            f.write('width' + ';')
            f.write('photo' + ';')
            f.write('description'  + '\n')
            for i in products:
                f.write(i['model']+';')
                f.write("'"+i ['name'] +"'"+ ';')
                f.write(i['quantity'] + ';')
                f.write(i['manufacturer'] + ';')
                f.write(i['min'] + ';')
                f.write(i['price'] + ';')
                f.write(i['categoryId'] + ';')
                f.write(i['width'] + ';')
                f.write("'"+i['photo'] +"'"+ ';')
                f.write("'"+i['description']+"'" + '\n')
        # Запишем файл с картинками
        with open('images.csv', 'w', encoding='utf-8') as f:
            f.write('model' + ';')
            f.write('image' + '\n')
            for i in images:
                list_images = i['links']
                for j in list_images:
                    f.write(i['model'] + ';')
                    f.write("'" +j+ "'"+ '\n')
        # Запишем файл с атрибутами

        with open('atributs.csv', 'w', encoding='utf-8') as f:
            #f.write('id' + ';')
            f.write('model' + ';')
            f.write('name' + ';')
            f.write('value' + '\n')
            for i in atributs:
                dict_params = i['params']
                for key,val in dict_params.items():
                    f.write(i['model'] + ';')
                    f.write("'" +key+"'" + ';')
                    f.write("'" +val+"'"+ '\n')

    def get_count(self):
        data = self.tree.xpath('//offer')
        return len(data)

    def __get_products(self):
        products=[]
        images = []
        atributs = []
        data = self.tree.xpath('//offer')
        for i in data:
            product = {}
            image = {}
            atribut = {}
            photos_links = []
            params = {}
            product['min']='1'
            product['width']='0'
            children=i.getchildren()
            if i.attrib['available'] == 'true':
                product['quantity'] = '100'
            for tag in children:
                if tag.tag == 'shop-sku':
                    product['model'] =  tag.text
                    image['model'] = tag.text
                    atribut['model'] = tag.text
                elif tag.tag == 'price':
                    product['price'] = tag.text
                elif tag.tag == 'categoryId':
                    product['categoryId'] =tag.text
                elif tag.tag == 'picture':
                    photos_links.append(str(tag.text))
                elif tag.tag == 'name':
                    product['name'] =(tag.text)
                    product['description'] =(tag.text)
                elif tag.tag == 'vendor':
                    product['manufacturer'] =(tag.text)
                elif tag.tag == 'weight':
                    product['width'] =(tag.text)
                elif tag.tag == 'description':
                    product['description'] =(tag.text)
                elif tag.tag == 'param':
                    if tag.attrib['name'] == 'Мин. упак':
                        product['min']=tag.text
                    elif '_' in  tag.attrib['name'] or tag.attrib['name'] == 'Штрихкод' or  'груп' in tag.attrib['name']:
                        pass
                    else:
                        params[tag.attrib['name']] = tag.text
            product['photo']=photos_links[0]
            image['links'] = photos_links
            atribut['params']=params
            products.append(product)
            images.append(image)
            atributs.append(atribut)
        return (products, images, atributs)

    def get_category_in_file(self):
        data = self.tree.xpath('//category')
        categorys=[]
        for i in data:
            category = {}
            category['id']=i.attrib['id']
            category['name'] = i.text
            try:
                category['parentId'] = i.attrib['parentId']
            except:
                category['parentId'] = '0'
            categorys.append(category)
        with open('categorys.csv', 'w', encoding='utf-8') as f:
            f.write('category_id' + ';')
            f.write('name' + ';')
            f.write('parentId' + '\n')
            for i in categorys:
                f.write(i['id']+ ';')
                f.write("'"+i['name']+"'" + ';')
                f.write(i['parentId']+ '\n')




if __name__=='__main__':
    wget.download('https://instrument.ru/yandexmarket/1b78da37-0b26-45a6-a885-095183509075.xml', 'yml_matrix.xml')
    load=load_matrix_yml('yml_matrix.xml')
    load.get_all_data_files()
    load.get_category_in_file()


