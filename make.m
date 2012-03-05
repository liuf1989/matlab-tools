function make(varargin)

dirbase = fileparts(mfilename('fullpath'));
old = cd(dirbase);

s = load('dependencies');
deps = s.deps;
dirs = s.dirs;
ndirs = length(dirs);

have = containers.Map(dirs, num2cell(false(1, ndirs)));
dirnum = containers.Map(dirs, num2cell(1:ndirs));

clonefmt = 'git clone https://github.com/dhr/%s.git';
pullfmt = 'cd %s; git pull; cd ..';

cellfun(@domake, varargin);

cd(old);

function domake(target)
  switch target
    case 'all'
      targs = dirs;
      quatloc = which('angle2quat');
      ourloc = fullfile(dirbase, 'quaternions');
      if ~isempty(quatloc) && ~strncmp(ourloc, quatloc, length(ourloc))
        targs = setdiff(targs, 'quaternions');
      end
      cellfun(@domake, targs);
    
    case 'update'
      files = dir;
      targs = {files([files.isdir]).name};
      targs = targs(~strncmp('.', targs, 1));
      cellfun(@domake, targs);
      
    otherwise
      if ~have.isKey(target)
        warning('Skipping unrecognized target ''%s''', target); %#ok<WNTAG>
        return;
      end
      
      if ~have(target)
        if isdir(fullfile(dirbase, target))
          system(sprintf(pullfmt, target));
        else
          system(sprintf(clonefmt, target));
          addpath(fullfile(dirbase, target));
        end
        
        have(target) = true;
        cellfun(@domake, dirs(deps(dirnum(target),:)));
      end
  end
end

end
