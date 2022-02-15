import click
# all logic is tested in fine_tune

def split_monolingual(path):
    resized_lines = []
    with open(path, encoding='utf-8') as f:
      lines = f.read().split('\n')
      for line in lines:
        words = line.split(' ')
        for i in range(0,len(words)-5,5):
          resized_lines.append(' '.join(words[i:i+10]))
    with open(path,'w', encoding='utf-8') as f:
      f.write('\n'.join(resized_lines))

@click.command()
@click.argument('path')

def main(path):# pragma: no cover
    split_monolingual(path)

if __name__ == '__main__':
    main()
