import click
import fastwer
import numpy as np
# all logic is tested in fine_tune

def pair_translated_sentences(path):
  with open(path, encoding='utf-8') as f:
      text = f.read()
  a_s = []
  b_s = []
  for line in text.split('\n'):
    if line.startswith('T-'):
      a_s.append(line[4:].replace(' ','').replace('\t',' ').replace('â',' '))
    if line.startswith('H-'):
      piz = line[4:].split('\t')
      piz = '\t'.join([piz[0],piz[-1]])
      if piz.startswith('-'):
        piz = ''.join(piz.split('\t')[1:])
      b_s.append(piz.replace(' ','').replace('\t',' ').replace('â',' '))
  print('pre',len(a_s),len(b_s))
  indices = list(map(lambda x: '<unk>' not in x, a_s))
  a_s = list(np.array(a_s)[indices])
  b_s = list(np.array(b_s)[indices])
  print('mid',len(a_s),len(b_s))
  indices = list(map(lambda x: (len(x[0])/len(x[1]))<1.25, zip(a_s,b_s)))
  a_s = list(np.array(a_s)[indices])
  b_s = list(np.array(b_s)[indices])
  print('after',len(a_s),len(b_s))
  return a_s, b_s

@click.command()
@click.argument('lang')
@click.option('-o','--output_folder','output_folder', type=click.Path())
@click.option('-s','--score','score', is_flag=True, default=False)

def main(lang, output_folder, score):# pragma: no cover
    path = 'back_'+lang+'/generate-test.txt'
    a_s, b_s = pair_translated_sentences(path)
    if score:
        print(fastwer.score(a_s, b_s, char_level=True), fastwer.score(a_s, b_s))
    if output_folder is not None:
        with open(output_folder+'/'+'back_'+lang+'.'+lang.split('-')[0],'w',encoding='utf-8') as f:
            f.write('\n'.join(a_s))
        with open(output_folder+'/'+'back_'+lang+'.'+lang.split('-')[1],'w',encoding='utf-8') as f:
            f.write('\n'.join(b_s))

if __name__ == '__main__':
    main()
