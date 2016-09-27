module Emcee

import RobustPmap

function sample(llhood, numwalkers, x0, numsamples_perwalker, thinning, a=2.)
	x = copy(x0)
	chain = Array(Float64, size(x0, 1), numwalkers, div(numsamples_perwalker, thinning))
	lastllhoodvals = RobustPmap.rpmap(llhood, map(i->x[:, i], 1:size(x, 2)))
	llhoodvals = Array(Float64, numwalkers, div(numsamples_perwalker, thinning))
	llhoodvals[:, 1] = lastllhoodvals
	chain[:, :, 1] = x0
	batch1 = 1:div(numwalkers, 2)
	batch2 = div(numwalkers, 2)+1:numwalkers
	divisions = [(batch1, batch2), (batch2, batch1)]
	for i = 1:numsamples_perwalker
		for ensembles in divisions
			active, inactive = ensembles
			zs = map(u->((a - 1) * u + 1) ^ 2 / a, rand(length(active)))
			proposals = map(i->zs[i] * x[:, active[i]] + (1 - zs[i]) * x[:, rand(inactive)], 1:length(active))
			newllhoods = RobustPmap.rpmap(llhood, proposals)
			for (j, walkernum) in enumerate(active)
				z = zs[j]
				newllhood = newllhoods[j]
				proposal = proposals[j]
				logratio = (size(x, 1) - 1) * log(z) + newllhood - lastllhoodvals[walkernum]
				if log(rand()) < logratio
					lastllhoodvals[walkernum] = newllhood
					x[:, walkernum] = proposal
				end
				if i % thinning == 0
					chain[:, walkernum, div(i, thinning)] = x[:, walkernum]
					llhoodvals[walkernum, div(i, thinning)] = lastllhoodvals[walkernum]
				end
			end
		end
	end
	return chain, llhoodvals
end

function flatten(chain, llhoodvals)
	numdims, numwalkers, numsteps = size(chain)
	newchain = Array(Float64, numdims, numwalkers * numsteps)
	for j = 1:numsteps
		for i = 1:numwalkers
			newchain[:, i + (j - 1) * numwalkers] = chain[:, i, j]
		end
	end
	return newchain, llhoodvals[1:end]
end

end
